# ec2-notebook

## Jupyter Notebookのセットアップと起動方法

### 1. EC2インスタンスへの接続
```bash
ssh -i <秘密鍵のパス> ec2-user@<EC2のパブリックIP>
```

### 2. 必要なパッケージのインストール
```bash
# システムの更新
sudo yum update -y

# Pythonと必要なパッケージのインストール
sudo yum install -y python3-pip python3-devel

# Jupyter Notebookのインストール
pip3 install jupyter
```

### 3. Jupyter Notebookの設定
```bash
# 設定ファイルの生成
jupyter notebook --generate-config

# パスワードの設定
jupyter notebook password
```

### 4. Jupyter Notebookの起動
```bash
# バックグラウンドでJupyter Notebookを起動
nohup jupyter notebook --ip=0.0.0.0 --no-browser &
```


## 注意事項
- セキュリティグループで8888ポートが開放されていることを確認してください
- 本番環境では、信頼できるIPアドレスからのみアクセスを許可することを推奨します
- データの永続化が必要な場合は、EBSボリュームの使用を検討してください
- より安全な環境のために、SSLの設定を推奨します