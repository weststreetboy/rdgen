@echo off
REM ============================================================
REM  RDGen 一键启动脚本（Windows）
REM  本地部署，不依赖 bryangerlach/rdgen 预构建镜像
REM  用法：双击本文件，或命令行执行 start_rdgen.bat
REM ============================================================

REM --- 必填：你的 GitHub 信息（用于触发 GitHub Actions 编译 RustDesk）---
set GHUSER=weststreetboy
set GHBEARER=your_github_fine_grained_token

REM --- 访问地址与产物加密密码（生成客户端时必须与 GitHub Secrets 一致）---
set GENURL=http://localhost:8000
set ZIP_PASSWORD=change_this_zip_password
set PROTOCOL=http
set REPONAME=rdgen
set GHBRANCH=master

REM --- 安全密钥（已生成，请勿外泄）---
set SECRET_KEY=change-me-to-a-random-secret-key

cd /d C:\Users\Administrator\WorkBuddy\2026-09-03-10-58-36\rdgen
REM 使用 waitress 生产级 WSGI 服务器（Windows 原生，比 runserver 更适合长期部署）
C:\Users\Administrator\.workbuddy\binaries\python\envs\rdgen\Scripts\python.exe -m waitress --port=8000 rdgen.wsgi:application
