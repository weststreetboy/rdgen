@echo off
REM ============================================================
REM  RDGen 一键启动脚本（Windows）
REM  本地部署，使用 weststreetboy/rdgen 仓库与本地构建镜像
REM  用法：双击本文件，或命令行执行 start_rdgen.bat
REM
REM  敏感值（GHBEARER / SECRET_KEY / ZIP_PASSWORD）请放在
REM  同目录的 secrets.local.bat（已 gitignore，不会进仓库），
REM  本脚本会自动 call 它。
REM ============================================================

REM --- 加载本地密钥（gitignored，可覆盖下面的默认值）---
if exist "%~dp0secrets.local.bat" call "%~dp0secrets.local.bat"

REM --- 必填：你的 GitHub 用户名（用于触发 GitHub Actions 编译 RustDesk）---
if not defined GHUSER set GHUSER=weststreetboy
if not defined GHBEARER set GHBEARER=your_github_fine_grained_token

REM --- 访问地址与产物加密密码（生成客户端时必须与 GitHub Secrets 一致）---
REM 本地访问：http://localhost:8000  即可（GitHub Actions 会从这里拉 secrets.zip 与产物）
REM 公网访问（如想让 GitHub Actions 公网可达）：先执行 start_rdgen_public.bat 启动 cloudflared，
REM   把它输出的 https://xxx.trycloudflare.com 填到下面 GENURL=，并把 PROTOCOL 改成 https
if not defined GENURL set GENURL=http://localhost:8000
if not defined ZIP_PASSWORD set ZIP_PASSWORD=CHANGE_ME_use_secrets_local_bat
if not defined PROTOCOL set PROTOCOL=http
if not defined REPONAME set REPONAME=rdgen
if not defined GHBRANCH set GHBRANCH=master

REM --- Django 安全密钥（推荐在 secrets.local.bat 里覆盖，保持 session 连续）---
if not defined SECRET_KEY set SECRET_KEY=change-me-to-a-random-secret-key

cd /d C:\Users\Administrator\WorkBuddy\2026-09-03-10-58-36\rdgen
REM 使用 waitress 生产级 WSGI 服务器（Windows 原生，比 runserver 更适合长期部署）
C:\Users\Administrator\.workbuddy\binaries\python\envs\rdgen\Scripts\python.exe -m waitress --port=8000 rdgen.wsgi:application
