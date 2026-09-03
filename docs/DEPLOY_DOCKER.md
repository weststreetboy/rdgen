# RDGen Docker 部署指南（群晖 NAS / 自托管，无需 Docker Hub）

本项目默认**从源码本地构建**，不依赖 Docker Hub。镜像只活在运行它的那台机器上，
不会发布到任何公共仓库。

---

## 0. 安全前提（务必先读）

镜像 **不包含任何运行时密钥**。以下文件被 `.gitignore` 与 `.dockerignore` 双重排除，
既不会进公开仓库，也不会被打进镜像：

- `secrets.local.bat` —— Windows 本地启动用的真值（ZIP_PASSWORD / SECRET_KEY / GHBEARER）
- `.env` —— Docker / compose 运行时用的真值
- `db.sqlite3`、以及 `png/ temp_zips/ exe/ media/` 运行时目录

运行时密钥只在容器启动时通过 compose 的 `environment:` 注入。仓库里只保留占位符模板：
`secrets.local.bat.example` 与 `.env.example`。

> 曾误把真实 `ZIP_PASSWORD` 写进 `docs/DEPLOY_PUBLIC.md`，已改为占位符。因为该值已在
> 公开仓库暴露过，**请务必轮换**：重新生成 `ZIP_PASSWORD`，并同步更新 GitHub 仓库 Secret
> 与本地 `.env`。

---

## 1. 在群晖 NAS 上拉起（Synology DSM 7.x）

### 1.1 准备

1. DSM → 套件中心 → 安装 **Container Manager**（即 Docker）。
2. 控制面板 → 终端机和 SNMP → 启用 SSH（部署时用，平时可关）。
3. 用 SSH 登录 NAS（`ssh <你的NAS账号>@<NAS内网IP>`），建一个项目目录，例如：
   ```sh
   mkdir -p /volume1/docker/rdgen
   cd /volume1/docker/rdgen
   ```
4. 拿代码（二选一）：
   - 有 git：`git clone https://github.com/weststreetboy/rdgen.git .`
   - 没 git：在电脑上把仓库下载 ZIP，解压到该共享文件夹。

### 1.2 填运行时密钥

```sh
cp .env.example .env
vi .env        # 或下载到电脑用记事本改完传回
```

至少填这些（其余保持默认）：

| 变量 | 填什么 |
|---|---|
| `SECRET_KEY` | `openssl rand -hex 32` 生成的随机串 |
| `GHUSER` | `weststreetboy` |
| `GHBEARER` | 你的 fine-grained token（Actions: Read and write） |
| `ZIP_PASSWORD` | 随机串，**必须与 GitHub 仓库 Secret `ZIP_PASSWORD` 完全一致** |
| `GENURL` | 见第 3 节；固定域名后为 `https://anglestudio.dpdns.org` |
| `PROTOCOL` | `https` |

### 1.3 构建并启动

```sh
cd /volume1/docker/rdgen
docker compose build          # 从源码构建镜像（只需首次，或代码更新后）
docker compose up -d          # 后台启动 rdgen
docker compose ps             # 确认状态
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000
```

> `docker-compose.yml` 默认 `build: .`，不再拉取任何已发布镜像。
> 构建时会从 Docker Hub **拉取基础镜像 `python:3.13-alpine`**（这是正常的，
> 只是下载基础层，不会把你自己的镜像上传到 Docker Hub）。
>
> 若你的 NAS 是 ARM 架构（部分 + 机型），alpine 也会自动选对应架构，无需改动。
> 若 `docker compose` 命令不存在，旧版用 `docker-compose`（带连字符）。

浏览器访问 `http://<NAS内网IP>:8000` 即可看到 "RustDesk Custom Client Builder"。

---

## 2. 固定公网域名：Cloudflare Named Tunnel（anglestudio.dpdns.org）

群晖在局域网内，GitHub Actions 必须能从公网回调它，所以需要隧道。
**好消息**：隧道直接由 compose 里的 `cloudflared` 服务跑，不用在 NAS 上单独装 cloudflared。

### 2.1 在你的电脑上创建 Named Tunnel（需浏览器登录 Cloudflare）

```bat
cloudflared tunnel login
cloudflared tunnel create rdgen
cloudflared tunnel route dns rdgen anglestudio.dpdns.org
cloudflared tunnel token rdgen
```

最后一条输出一段 token。把它填进 NAS 上的 `.env`：

```
TUNNEL_TOKEN=eyJ...你的隧道token...
GENURL=https://anglestudio.dpdns.org
PROTOCOL=https
```

### 2.2 关键一步：在 Cloudflare 后台设置 ingress 目标

Cloudflare Zero Trust → Networks → Tunnels → `rdgen` → Public Hostname，
确认 `anglestudio.dpdns.org` 指向：

```
http://rdgen:8000
```

> **大坑**：不是 `localhost:8000`。`cloudflared` 跑在 compose 网络里，它的
> `localhost` 是隧道容器自己，必须写服务名 `rdgen` 才能解析到 RDGen 容器。

### 2.3 带隧道一起启动

```sh
docker compose --profile tunnel up -d
```

只有加了 `--profile tunnel`，`cloudflared` 服务才会启动。它 `depends_on: rdgen`，
会自动等 RDGen 起来。

---

## 3. 必须一致的几处值

| 位置 | 值 | 说明 |
|---|---|---|
| GitHub Secret `ZIP_PASSWORD` | 与 `.env` 的 `ZIP_PASSWORD` 完全一致 | 否则 Actions 解不开加密包，构建永远不开始 |
| GitHub Secret `GENURL` | `https://anglestudio.dpdns.org` | 与 `.env` 的 `GENURL` 一致 |
| `.env` 的 `GHUSER` / `GHBEARER` | 你的账号 / fine-grained token | Actions: Read and write |
| Cloudflare ingress | `http://rdgen:8000` | 见 2.2 |

---

## 4. 排错

- **Actions 404 / 拉不到 secrets.zip** → `GENURL` 不可公网访问，或 `PROTOCOL` 没设 https
- **zip 解压失败** → `ZIP_PASSWORD` 本地与 GitHub Secret 不一致
- **域名访问 503** → Cloudflare ingress 写成了 `localhost:8000`（应是 `rdgen:8000`）
- **容器起不来，SQLite 报错** → 旧 `./db.sqlite3` 文件绑定已改为命名卷 `rdgen_db`，删掉残留空目录后重跑
- **构建慢 / 拉不到基础镜像** → NAS 需要能访问 Docker Hub 拉取 `python:3.13-alpine`（仅下载，不上传）
