# pbadds

模擬多檔案拖拉到應用程式的行為

例如: 使用lmstudio上傳檔案時，可以利用此工具來複製所需的檔案至剪貼簿後再貼上


## Install


```sh
git clone https://github.com/CarsonSlovoka/pbadds.git
cd pbadds
swiftc -o pbadds pbadds.swift # 生成該執行檔
./pbadds --version
# pbadds version 1.0.0
sudo mv -v pbadds /usr/local/bin/  # (可選, 此位置通常已在PATH變數之中，所以搬過來後可以直接使用)

pbadds -v
```

## Usage

```sh
pbadds ~/path/to/myfile

# 相對路徑
pbadds README.md

# 多檔案
pbadds README.md ~/path/to/myfile
```
