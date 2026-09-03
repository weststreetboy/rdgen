# RDGen Docker 部署 + 固定域名（Cloudflare）指南

本仓库已支持 Docker 部署：镜像通过 GitHub Actions 构建并推送到 Docker Hub，
你只需 `docker compose pull` 即可在任何机器上拉起。

---

## 0. 安全前提（务必先读）

镜像 **不包含任何运行时密钥**。以下文件被 `.gitignore` 与 `.dockerignore` 双重排除，
既不会进公开仓库，也不会被打进镜像：

- `secrets.local.bat` —— Windows 本地启动用的真值（ZIP_PASSWORD / SECRET_KEY / GHBEARER）
- `.env` —— Docker / compose 运行时用的真值
- `db.sqlite3`、以及 `png/ temp_zips/ exe/ media/` 运行时目录

运行时密钥只在容器启动时通过 compose 的 `environment:` 注入。仓库里只保留
占位符模板：`secrets.local.bat.example` 与 `.env.example`。

> 曾经在 `docs/DEPLOY_PUBLIC.md` 误写入过真实 `ZIP_PASSWORD`，已改为占位符。
> 因为该值已在公开仓库暴露过，**请务必轮换**：重新生成 `ZIP_PASSWORD`，
> 并同步更新 GitHub 仓库 Secret 与本地 `secrets.local.bat`。

---

## 1. 把镜像发到 Docker Hub（用你自己的 GitHub Actions）

沙箱环境无法直连 Docker Hub，所以用仓库自带的 Actions 工作流来构建/推送，
它运行在 GitHub 的 CI 里，能正常访问 Docker Hub。

1. 打开 https://github.com/weststreetboy/rdgen/settings/secrets/actions
   添加两个仓库 Secret：
   - `DOCKERHUB_USERNAME` = `weststreetboy`（保持与镜像名一致）
   - `DOCKERHUB_TOKEN` = Docker Hub Access Token
     （Docker Hub → Account Settings → Security → New Access Token，scope: `public_repo`）
2. 把本仓库推到 GitHub（含新增的 `docker-publish.yml`）：
   ```bat
   git add -A && git commit -m "Add Docker publish workflow and placeholder templates" && git push origin master
   ```
3. 打开 https://github.com/weststreetboy/rdgen/actions/workflows/docker-publish.yml
   → **Run workflow**。完成后镜像出现在 `docker.io/weststreetboy/rdgen:latest`。

---

## 2. 在目标机器拉起 RDGen

前置：已安装 Docker + Docker Compose v2。

```bat
REM 1) 从模板生成运行时 .env（填入真实值，勿提交）
cp .env.example .env
notepad .env
REM   至少填：SECRET_KEY / GHUSER / GHBEARER / ZIP_PASSWORD
REM   GENURL 见第 4 节（固定域名后为 https://anglestudio.dpdns.org）

REM 2) 拉镜像并启动
docker compose pull
docker compose up -d

REM 3) 验证
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000
```

`docker-compose.yml` 已把运行时目录挂载出来（`exe/ png/ temp_zips/ media/`），
数据库用命名卷 `rdgen_db`（避免宿主机缺文件时 Docker 把它建成目录导致 SQLite 报错）。

---

## 3. 固定公网域名：Cloudflare Named Tunnel（anglestudio.dpdns.org）

比 Quick Tunnel 好：域名固定不变，不用每次重启改 Secret。

### 3.1 在你的机器上创建 Named Tunnel（需浏览器登录 Cloudflare）

```bat
cloudflared tunnel login
cloudflared tunnel create rdgen
cloudflared tunnel route dns rdgen anglestudio.dpdns.org
cloudflared tunnel token rdgen
```

最后一条命令会输出一段 token。把它填进 `.env`：

```
TUNNEL_TOKEN=eyJ...你的隧道token...
GENURL=https://anglestudio.dpdns.org
PROTOCOL=https
```

### 3.2 关键一步：在 Cloudflare 后台设置 ingress 目标

打开 Cloudflare Zero Trust → Networks → Tunnels → `rdgen` → Public Hostname，
确认 `anglestudio.dpdns.org` 指向：

```
http://rdgen:8000
```

> **大坑**：不是 `localhost:8000`。`cloudflared` 跑在 compose 网络里，
> 它的 `localhost` 是隧道容器自己，必须写服务名 `rdgen` 才能解析到 RDGen 容器。

### 3.3 带隧道一起启动

```bat
docker compose --profile tunnel up -d
```

只有加了 `--profile tunnel`，`cloudflared` 服务才会启动。它 `depends_on: rdgen`，
会自动等 RDGen 起来。

---

## 4. 必须一致的几处值

| 位置 | 值 | 说明 |
|---|---|---|
| GitHub Secret `ZIP_PASSWORD` | 与 `.env` 的 `ZIP_PASSWORD` 完全一致 | 否则 Actions 解不开加密包，构建永远不开始 |
| GitHub Secret `GENURL` | `https://anglestudio.dpdns.org` | 与 `.env` 的 `GENURL` 一致 |
| `.env` 的 `GHUSER` / `GHBEARER` | 你的账号 / fine-grained token | Actions: Read and write |
| Cloudflare ingress | `http://rdgen:8000` | 见 3.2 |

---

## 5. 排错

- **Actions 404 / 拉不到 secrets.zip** → `GENURL` 不可公网访问，或 `PROTOCOL` 没设 https
- **zip 解压失败** → `ZIP_PASSWORD` 本地与 GitHub Secret 不一致
- **域名访问 503** → Cloudflare ingress 写成了 `localhost:8000`（应是 `rdgen:8000`）
- **容器起不来，SQLite 报错** → 旧 `./db.sqlite3` 文件绑定已改为命名卷，删掉残留的空目录后重跑
- **镜像巨大 / 含源码** → 正常，源码在公开仓库本就公开；密钥已被 `.dockerignore` 排除
