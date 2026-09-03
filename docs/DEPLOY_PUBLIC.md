# RDGen 公网部署 / 公网 GENURL 配置指引

> **背景**：RDGen 在触发 GitHub Actions 编译 RustDesk 客户端后，Actions 需要从
> 一个**公网可达**的 URL 拉回 `secrets.zip` 与 `keys.txt`。如果只暴露 `localhost:8000`，
> Actions 是访问不到的（沙箱/局域网都没有公网入口）。
> 这份文档说明怎么把它暴露到公网，并把 URL 配到 GitHub Secrets。

---

## 1. 准备 GitHub 仓库 Secrets

打开 https://github.com/weststreetboy/rdgen/settings/secrets/actions → **New repository secret**

| 名字 | 值 | 说明 |
|---|---|---|
| `GENURL` | （稍后填）`https://你的域名.trycloudflare.com` | RDGen 的公网入口（必须 https，**不要**带尾斜杠） |
| `ZIP_PASSWORD` | `15eeafa33b395418fd1e0f183bf9009f4a8fd1d5fb104128274fb549bb9214d2` | 必须和 `start_rdgen.bat` 里 `set ZIP_PASSWORD=` 的值**完全一致** |

> 同步设置：仓库 → Settings → General → 勾选 **Allow GitHub Actions to create and approve pull requests**。
> Actions → 第一次访问时点绿色 **Enable Actions** 按钮。

---

## 2. 准备 GitHub fine-grained Personal Access Token（PAT）

打开 https://github.com/settings/personal-access-tokens/new

- Token name: `rdgen-trigger`
- Resource owner: `weststreetboy`
- Repository access: **Only select repositories** → 选 `weststreetboy/rdgen`
- Permissions → Repository permissions:
  - **Actions**: Read and write
  - **Contents**: Read and write  （推荐，避免某些边界场景报错）
  - **Metadata**: Read-only（默认即可）

生成后把 token 粘到 `start_rdgen.bat` 的 `set GHBEARER=...`（替换 `your_github_fine_grained_token`）。
**不要**把这个 token 提交到任何 Git 仓库 —— 建议保持本地修改不入仓，或用 `git update-index --skip-worktree start_rdgen.bat` 让 git 忽略本地改动。

---

## 3. 选择公网暴露方案

### 方案 A：Cloudflare Quick Tunnel（最快，零账号）

**优点**：一行命令，无需注册 Cloudflare，无需自有域名。
**缺点**：每次重启域名会变（要同步改 GitHub Secret）。生产不建议长期用，但**第一次跑通流程**最方便。

1. 下载 cloudflared：
   - 浏览器访问 https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
   - 另存为 `cloudflared.exe`，放到 `C:\Windows\System32\`（或任意 PATH 目录）
2. 双击 `start_rdgen_public.bat`（仓库根目录）—— 它会拉起 waitress + cloudflared 两个窗口
3. 在 cloudflared 窗口找到 `Your quick Tunnel has been created!` 下面那行 `https://*.trycloudflare.com`
4. 把这个 URL 填到：
   - `start_rdgen.bat` → `set GENURL=https://xxx.trycloudflare.com` 并把 `set PROTOCOL=https`
   - GitHub → `weststreetboy/rdgen` → Settings → Secrets → `GENURL` = 同一个 URL
5. 重新跑一次 `start_rdgen.bat` 让新 GENURL 生效，再回 Web UI 生成客户端测试

### 方案 B：Cloudflare Named Tunnel（固定域名，长期方案）
- 需要一个**托管在 Cloudflare 的域名**
- 一次性 `cloudflared tunnel login` + `cloudflared tunnel create rdgen` + DNS 指向 + `cloudflared tunnel route dns`
- 之后 `cloudflared tunnel run rdgen` 启动即可，URL 固定不变
- 详细命令见 Cloudflare 官方文档：https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

### 方案 C：ngrok（需注册）
- 注册 https://ngrok.com → 拿 authtoken → `ngrok config add-authtoken <token>`
- `ngrok http 8000`
- 免费版每次重启域名变，付费版可固定

### 方案 D：路由器端口映射 / 公网 IP
- 如果你的宽带有公网 IPv4，在路由器把 8000 端口映射到本机
- 用 DDNS（如阿里云 / dnspod / Cloudflare API）绑定一个域名
- 注意：国内运营商常屏蔽家用宽带 80/443 端口，建议用高位端口 + Cloudflare Origin Rules

---

## 4. 验证清单（生成第一个客户端之前）

- [ ] 本地 `http://localhost:8000` 打开能看到 "RustDesk Custom Client Builder"
- [ ] `start_rdgen_public.bat` 跑起来，cloudflared 窗口有公网 URL
- [ ] `start_rdgen.bat` 的 `GENURL` / `PROTOCOL` 已改成 https + 公网 URL
- [ ] GitHub `weststreetboy/rdgen` Secrets：`GENURL`（公网 URL）+ `ZIP_PASSWORD`（与 bat 一致）
- [ ] `GHUSER`=weststreetboy，`GHBEARER`=有效的 fine-grained token
- [ ] GitHub 仓库 Actions 已 Enable
- [ ] 上传图标 ≥ 512×512（UI 上传时会自动校验并警告）
- [ ] 提交一个测试 build，watch Actions run 是否成功把产物传回 `/api/return-build`

---

## 5. 常见坑

- **Actions 报 404 / 拉不到 secrets.zip** → `GENURL` 不公网可达，或者 `PROTOCOL` 没改 https
- **产物上传失败** → GitHub PAT 权限不足（Actions: Read+Write 是最低要求）
- **zip 解压失败** → `ZIP_PASSWORD` 本地与 GitHub Secret 不一致
- **域名每次变** → 用 Named Tunnel 或 ngrok 付费版