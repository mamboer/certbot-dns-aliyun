# Certbot DNS Aliyun

一个基于 Docker 的自动化解决方案，通过 Let's Encrypt 获取和管理 SSL/TLS 证书，使用阿里云 DNS 进行域名验证。

注：项目基于 [justjavac](https://github.com/justjavac) 的同名项目 [certbot-dns-aliyun](https://github.com/justjavac/certbot-dns-aliyun) 迭代开发。

## 功能特点

- 使用 Let's Encrypt 自动获取免费 SSL/TLS 证书
- 通过阿里云 DNS API 自动完成 DNS-01 验证挑战
- 支持多域名证书申请和管理
- 自动为顶级域名添加通配符证书（例如：*.example.com）
- 使用 cron 任务自动定期续期证书
- 支持通过 .env 文件简化配置
- 证书自动部署到指定目录

## 快速开始

### 安装

1. 克隆项目仓库：
```bash
git clone https://github.com/mamboer/certbot-dns-aliyun.git
cd certbot-dns-aliyun
```

2. 构建 Docker 镜像：
```bash
docker build -t certbot-dns-aliyun .
```

### 使用方法

#### 方法一：使用环境变量

```bash
docker run -d \
  -e REGION="cn-hangzhou" \
  -e ACCESS_KEY_ID="your-access-key-id" \
  -e ACCESS_KEY_SECRET="your-access-key-secret" \
  -e DOMAINS="example.com,sub.example.com" \
  -e EMAIL="your-email@example.com" \
  -v /path/to/certificates:/etc/letsencrypt/certs \
  --name certbot-dns-aliyun \
  certbot-dns-aliyun
```

#### 方法二：使用 .env 文件（推荐）

1. 创建 .env 文件：
```
REGION=cn-hangzhou
ACCESS_KEY_ID=your-access-key-id
ACCESS_KEY_SECRET=your-access-key-secret
DOMAINS=example.com,sub.example.com
EMAIL=your-email@example.com
# 可选，默认为 "0 0 * * *"
CRON_SCHEDULE=0 0 * * *
```

2. 运行 Docker 容器：
```bash
docker run -d \
  -v /path/to/.env:/.env \
  -v /path/to/certificates:/etc/letsencrypt/certs \
  --name certbot-dns-aliyun \
  certbot-dns-aliyun
```

## 配置选项

### 必选环境变量

| 环境变量 | 说明 |
|----------|------|
| REGION | 阿里云区域，例如：cn-hangzhou |
| ACCESS_KEY_ID | 阿里云访问密钥ID |
| ACCESS_KEY_SECRET | 阿里云访问密钥密钥 |
| DOMAINS | 要获取证书的域名列表，使用逗号分隔 |
| EMAIL | 证书所有者的电子邮件地址 |

### 可选环境变量

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| CRON_SCHEDULE | 0 0 * * * | 证书自动续期的 cron 表达式（默认每天 0 点） |

## 证书文件

证书会自动保存在容器内的 `/etc/letsencrypt/certs/` 目录中：

- `fullchain.pem` - 包含服务器证书和中间证书
- `privkey.pem` - 证书私钥
- `cert.pem` - 服务器证书
- `chain.pem` - 中间证书

通过挂载卷，可以在主机上访问这些文件。

## 域名处理逻辑

- 对于顶级域名（如 example.com），会自动添加通配符证书（*.example.com）
- 对于子域名（如 sub.example.com），只获取该特定子域名的证书
- 多个域名使用逗号分隔，例如：`example.com,sub.example.com,another.com`

## 手动续期

如果需要手动续期证书，可以执行：

```bash
docker exec certbot-dns-aliyun /usr/local/bin/entrypoint.sh renew
```

## 安全提示

- 使用具有最小权限的阿里云访问密钥（只需要DNS修改权限）
- 避免将密钥直接硬编码在 Dockerfile 或命令行中
- 推荐使用 .env 文件或 Docker 密钥管理功能

## 故障排除

- 检查阿里云 DNS API 权限
- 查看容器日志了解详细错误信息：`docker logs certbot-dns-aliyun`
- 确保域名已在阿里云 DNS 服务中正确配置

## 自动化构建

本项目配置了 GitHub Actions 工作流，可以在代码提交到 main 分支时自动构建 Docker 镜像并推送到：

1. Docker Hub: `[你的 DockerHub 用户名]/certbot-dns-aliyun`
2. 阿里云容器镜像服务: `[你的阿里云容器镜像注册地址]/[你的容器镜像服务命名空间]/certbot-dns-aliyun`

### 配置自动化构建

要启用自动化构建，需要在 GitHub 仓库中配置环境和密钥：

1. 创建环境：
   - 进入 GitHub 仓库的 Settings -> Environments
   - 点击 "New environment" 创建名为 `PROD` 的环境

2. 添加 Secrets 和 Variables：
   - 在 `PROD` 环境下添加以下 Secrets：

   | 密钥名称 | 说明 |
   |----------|------|
   | DOCKERHUB_TOKEN | Docker Hub 访问令牌（不是密码） |
   | ALIYUN_CR_USERNAME | 阿里云容器镜像服务用户名 |
   | ALIYUN_CR_PASSWORD | 阿里云容器镜像服务密码或访问令牌 |
   | ALIYUN_CR_URL | 阿里云容器镜像服务注册地址，**格式要求**：不要包含 http:// 或 https:// 前缀，不要以斜杠 / 结尾） |

   - 在 `PROD` 环境下添加以下 Variables：
   
   | 变量名称 | 说明 |
   |----------|------|
   | DOCKERHUB_USERNAME | Docker Hub 用户名 |
   | ALIYUN_CR_NAMESPACE | 阿里云容器镜像服务命名空间 |

3. 环境保护规则（可选）：
   - 可以为 `PROD` 环境添加保护规则，如需要审批才能部署到该环境

### 手动触发构建

除了通过提交到 main 分支自动触发外，您还可以在 GitHub 仓库的 Actions 页面手动触发工作流。

### 构建标签

自动构建的镜像会包含以下标签：
- `latest`: 最新构建
- 语义化版本号（如有 Git 标签）
- 短 Git SHA 哈希值

### 自动构建故障排除

如果您遇到类似 `invalid tag "***//certbot-dns-aliyun:latest": invalid reference format` 的错误，请检查：

1. **阿里云容器镜像服务地址格式**：
   - 确保 `ALIYUN_CR_URL` 的格式正确，例如 `registry.cn-hangzhou.aliyuncs.com`
   - 不要包含 `http://` 或 `https://` 前缀
   - 不要在末尾添加斜杠 `/`

2. **命名空间格式**：
   - 确保 `ALIYUN_CR_NAMESPACE` 只包含允许的字符（字母、数字、短横线）
   - 不要在开头或结尾添加斜杠

3. **查看详细日志**：
   - 在 GitHub Actions 日志中查找更详细的错误信息
   - 尝试手动构建和推送镜像，验证凭据和配置

## 许可证

[MIT License](LICENSE)
