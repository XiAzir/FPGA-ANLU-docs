# C11307 / C11206 媒体路径只读审计

日期：2026-10-14（北京时间）  
范围：只读比较 `development/player_spectrum_observed` 与已验证基线 `development/player_bmp_scale` 的 FAT32 目录扫描、文件簇链映射、WAV/BMP 读路径、SD 扇区仲裁和频谱新增逻辑。未运行构建、未改 HDL。实板数据来自用户视频及其解码反馈。

## 结论

目前没有证据把“WAV 杂音 + BMP 未显示”定为同一 RTL 根因。较新的视频解码把 BMP 支路收窄到 loader：`fs_ready=1`、`bmp_error=1`、`wav_primed=1`，其余文件/映射错误标志无错，具体为 `bmp_map_error=0`。因此不是挂载失败，也不是 FAT 簇映射器报错；需区分 BMP 头长度/校验、scaler、等待 watchdog 或写帧提交。BMP RTL 没有错误阶段码，当前 `bmp_error` 一位不足以确定是哪一种。

用户反馈 `IMG0/0` 并不能证明 `fs_bmp_count=0`。`player_osd_state.v:50-64,95-102,136-137` 的 `frame_pixel` 复位值为 0，首帧被提交前 OSD 可以保持无效帧的 `0/0`；而本轮已有 `bmp_error=1`，这与“BMP首帧未提交”吻合。目录计数仍须单独读取确认。

默认 WAV 有杂音、tone 声音正常，但不能据此认定当前听到杂音来自 WAV PCM 错误。源码 `player_pcm_prefix_probe.v:3-5,39-42` 的 CRC 每次复位跳过 65,536 个有效样本，随后对 32,768 个 16-bit 样本做 CRC-16/CCITT-FALSE（低字节先、高字节后，init FFFF/poly 1021）。WAV parser 的 `data_offset` 是相对文件偏移；本地 60 秒 `deliverables/real_music_20261008/card/TEST.WAV` 的 data 起点为 0x2C。独立离线复算该文件跳过65,536样本后的窗口 CRC 为 F485；旧8秒音阶 `bringup/tf_wav_hdmi/card_media/TEST.WAV` 同位置为 6ACD。因此板上三端 `F485` 与当前60秒素材窗口一致，且 flags7/badformat0；这是有限窗口的强佐证，不能证明TF实物文件哈希一致或其余约58秒序列无丢样。源/ FIFO / HDMI 前缀一致说明窗口内 PCM 数据一路一致；需继续看其他时段、underflow或 HDMI输出层。B 计数增长，C 为 `FE0000/FE0006`（WAV）及 `FE035F/FE036D`（tone），说明 FFT有完成及非零输出。注意当前顶层 B/C 已被改作频谱遥测（`top_tf_hdmi_audio.v:537-539`），不再连接 `data_offset_sync`；视频中读到的 `offset=8000` 不能仅凭当前 B/C 映射解释，当前可复核的素材 data offset 是 0x2C。

两工程的 `fat32_catalog.v`、`fat32_file_sector.v`、`sd_sector_arbiter.v`、`tf_wav_file_player.v`、`tf_bmp_file_player.v` 内容逐字相同（PowerShell SHA256 比较相等）。顶层差异新增频谱诊断连线、B/C 页遥测复用和 BUILD_ID；未修改 FAT/文件/仲裁 RTL。频谱只采样 pixel clock 域的 `audio_valid/audio_pcm`，内部 RAM/ROM 独立（`player_pcm_waveform.v:20-28`、`player_spectrum_analyzer.v:50-69,214-255`、`top_tf_hdmi_audio.v:398-405`），不存在到 SD 请求、文件映射或帧缓存写端的直接 RTL 连接。频谱带来的新增 BRAM/逻辑可能改变全局布局和时序，这是物理实现假设，不是已证实原因。

## 代码路径和具体检查

- **FAT 挂载/目录项**：顶层 `top_tf_hdmi_audio.v:200-208` 将启动扇区、FAT 与根目录扫描交给 `fat32_catalog`。目录项匹配及 BMP/WAV 元数据更新在 `fat32_catalog.v:156-180`；启动时计数和找到标志清零在 `fat32_catalog.v:107-124`。扫描器检查每个扇区必须恰好 512 字节且 end 独立出现（`fat32_catalog.v:129-197`），但没有 SD 内容 CRC。因此 `fs_ready=1` 证明挂载流程完成，不等于媒体数据内容经过校验。
- **文件簇链/缓存**：BMP/WAV 是两个独立的 `fat32_file_sector` 实例，接在 `top_tf_hdmi_audio.v:227-247`。逻辑扇区映射到目标簇，必要时读取 FAT 项（`fat32_file_sector.v:131-197`）。所谓 cache 是单项顺序簇缓存：仅存最近成功簇、逻辑索引和链走访状态（`fat32_file_sector.v:27-37,143-162`），在一个完整数据扇区成功后更新（`fat32_file_sector.v:241-263`）；没有 512 字节数据缓存，也没有 BMP/WAV 间共享缓存。对比未发现 C11307 改动或静态可证实的缓存错误。
- **扇区仲裁**：两映射器合用一个 `sd_sector_arbiter` 和卡控制器（`top_tf_hdmi_audio.v:417-437`）。仲裁仅在扇区边界切换；BMP 等待时至多先给 WAV 两扇区，随后转 BMP（`sd_sector_arbiter.v:1-2,27-40`），每次结束后有两个仲裁空拍（`sd_sector_arbiter.v:28-34`）。这是唯一直接的 BMP/WAV 资源竞争点。代码显示有界音频优先意图，但尚无板端仲裁 owner/欠载计数证明它造成杂音。
- **WAV 播放**：`tf_wav_file_player.v:309-340` 在 `ST_PLAY_REQ` 确认 FIFO 有空间才读一个扇区，并在活动态只把 RIFF data 区域字节配成 PCM；`sd_end` 要求 512 个字节（`tf_wav_file_player.v:336-340`）。超时和 mapper error 的处理在 `tf_wav_file_player.v:332-360`。因此“有声但杂音”仍可能是内容错误或间歇欠载；prefix/badformat 仅覆盖有限窗口/格式字段，无法区分。
- **BMP 读头、缩放和提交**：loader 在 `IDLE` 只有 `catalog_ready && bmp_count!=0` 才选首图并清解析寄存器（`tf_bmp_file_player.v:108-123`）；`HEADER` 数 512 字节并提取头字段（`tf_bmp_file_player.v:125-153`）；`CHECK` 的 `header_ok` 验证 `BM`、DIB、像素偏移、24-bit BI_RGB、宽高和文件范围（`tf_bmp_file_player.v:41-56,155-157`）；`PAYLOAD` 处理 scaler 错误/完成（`tf_bmp_file_player.v:168-176`）；之后需要 frame write finish 才置 `display_valid`（`tf_bmp_file_player.v:178-182`）。`bmp_error` 可由头扇区长度异常、`!header_ok`、`scale_error`、映射 `file_error`、错误状态或 watchdog 触发（`tf_bmp_file_player.v:149-157,168-188`）。watchdog 覆盖 HEADER/WRITE_WAIT/COMMIT，阈值默认 50,000,000 个 SD 时钟周期，PAYLOAD 自身由 scaler/mapper 的等待逻辑负责（`tf_bmp_file_player.v:7,103-106,186-188`）。顶层把 `bmp_error` 与 `bmp_map_error` 分开接入现有文件状态（`top_tf_hdmi_audio.v:540-547`）；本轮 `bmp_map_error=0`，优先定位 loader 头检查、scaler、write handshake/watchdog，而不是直接归咎 FAT mapper。
- **BMP scaler 内部 sector BRAM**：`bmp_scale_engine.v:67-85` 声明 512×8 sector RAM 和 1024×24 row RAM，按同步读方式使用；`bmp_scale_engine.v:72-75` 在有效卡字节到来时写 sector RAM。它是 BMP 数据缓存，与簇链 cache 完全不同。当前用户视频未提供 loader 停止的 `state_code`、头部字段或 scaler 状态，无法确定是否此 RAM 读写、扇区 tag、SD 同步接口或 frame buffer handshake 导致错误。帧 buffer 跨 `sd_card_clk/ext_mem_clk/video_clk`，顶层连接在 `top_tf_hdmi_audio.v:321-347`；C11307 未改接口/RTL，但新资源可能改路由。
- **频谱**：分析器按 `audio_valid` 收 1024 样本，其余时间执行窗、FFT、分频扫描（`player_spectrum_analyzer.v:1-3,282-375`）；它不对音频播放器施加 backpressure，非采集态的样本会被主动忽略。频谱正常只说明部分 PCM 有效并完成计算，不能证明全程 PCM 正确。

## “共同故障”判断

两症状在用户反馈中共现，但现在存在两个不同已知信号：BMP 支路的 `bmp_error=1`（且 mapper error 为 0）；WAV 的 32,768样本延后窗口与本地60秒 canonical 的 CRC匹配，但听感仍异常。只要窗口捕获一致，杂音仍可能发生在未覆盖WAV区段、后续供数/underflow或HDMI实际输出层；亦可能是共享SD/跨域物理通道或本版布局影响。BMP error和WAV听感问题仍可能独立。当前源码差异不足以证明共因。成功基线 C11206 的旧实板通过不能证明本轮 C11307 的 SD 线波形、卡数据、CDC 边沿或布局状态。

不可当根因写入的候选：

- WAV 对 BMP 的扇区优先策略导致 WAV FIFO 欠载；仅凭 RTL 策略不能证明实板欠载。
- C11307 新增 BRAM/组合逻辑导致 SD 或帧缓存 CDC 路径边缘失效；需路由/板端状态证据。
- BMP header 字节错误、`header_ok` 不通过、scaler 出错、watchdog 或 frame write/commit 超时；当前未有失败阶段码。
- WAV 文件 sector 内容错误、FAT 链错或 PCM bridge 欠载；当前 `wav_map_error=0` 和有限 prefix pass 不能排除其他问题。

## 最小后续诊断/修复

先使用已有 D/B/C 与状态页 0 再录一轮。状态页 0 已接入 `fs_ready/fs_error/display_valid/bmp_error/wav_primed/wav_error/bmp_map_error/wav_map_error`（`top_tf_hdmi_audio.v:540-547`）。页面 B/C 已验证能观察 FFT 活性，本轮需要补上 BMP loader 阶段信息，而非重写 FAT/仲裁。

最小诊断候选建议增加 sticky `bmp_error_stage/error_cause`，在 header sector 长度、`header_ok` 比较失败、`scale_error`、mapper error、watchdog、WRITE_WAIT/COMMIT 握手处编码；同时显示 `state_code`、`fs_bmp_count`、`display_valid`。如仍需解释 WAV 杂音，再加 arbiter owner/streak/sector address、WAV FIFO 水位、underflow 计数；只有 underflow 或数据证据指向供给时才改配额/预取。若 BMP 错在 `header_ok`，保存/显示解析出的 magic、width、height、pixel_offset、declared_size/file_size，并和 TF 原始 BMP 头核对；若停在 scaler，再检查同步 BRAM 的 `sector_tag/sector_raddr`、扇区读写使能和请求握手；若到 COMMIT，检查 `write_req_ack`、`frame_write_finish` 与其 CDC toggle。每个修复都跟随上述定位结果，不动成功基线及冻结候选。

## 审计方法/边界

只读使用 PowerShell SHA256 比较五个媒体模块并检查当前 HDL 行号；未运行仿真、构建或上板操作。行号对应 2026-10-14 当前文件。实物反馈/视频解码由用户提供；没有实物卡镜像、SD 总线捕获、BMP error stage、完整WAV其余区段 CRC、frame-buffer handshake 波形或当前位流路由复核，因此仍不能给出唯一根因。
