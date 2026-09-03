@echo off
REM ============================================================
REM  RDGen 公网模式启动：waitress + cloudflared quick tunnel
REM
REM  效果：把本地 http://localhost:8000 暴露成 https://xxx.trycloudflare.com
REM  用法：双击本文件，会打开两个窗口 —— 一个跑 waitress，一个跑 cloudflared
REM  取 URL：cloudflared 窗口出现 "Your quick Tunnel has been created!" 后，
REM         复制下面的 https://xxx.trycloudflare.com，填到：
REM           1. start_rdgen.bat 的 GENURL=  (改完后把 PROTOCOL 也改成 https)
REM           2. GitHub -> weststreetboy/rdgen -> Settings -> Secrets -> GENURL
REM ============================================================

REM ---- 0. 检测 cloudflared ----
where cloudflared >nul 2>nul
if errorlevel 1 (
  echo [X] cloudflared 未安装。请先下载：
  echo     https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
  echo     下载后把它放到 C:\Windows\System32 或与本脚本同目录，然后重试。
  pause
  exit /b 1
)

echo [1/2] 启动 waitress（本地服务）...
start "RDGen-waitress" cmd /k start_rdgen.bat

echo [2/2] 等 waitress 就绪后启动 cloudflared quick tunnel...
timeout /t 6 /nobreak >nul

start "RDGen-cloudflared" cmd /k cloudflared tunnel --url http://localhost:8000 --no-autoupdate

echo.
echo ============================================================
echo  waitress 窗口：本地 waitress 启动日志（应看到 "Serving on http://0.0.0.0:8000"）
echo  cloudflared 窗口：等待出现 "Your quick Tunnel has been created!" 字样
echo                   下面那行的 https://*.trycloudflare.com 就是公网 GENURL
echo ============================================================
echo  取到 URL 后做两件事：
echo    A) 写入 start_rdgen.bat:  GENURL=https://你的URL  PROTOCOL=https
echo    B) GitHub -> weststreetboy/rdgen -> Settings -> Secrets -> GENURL = 同一个 URL
echo  ZIP_PASSWORD 用 start_rdgen.bat 里的 15eeafa33b39...d2（已与本仓库约定）
echo ============================================================
pause