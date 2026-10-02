# GuruGuruKeyBoard / くるくるキーボード

文字が横に流れるiPhone用のカスタム日本語キーボードMVP。Googleの公式アプリではありません。

## 機能

3本の文字レーン、停止・再開、3段階速度、かな/ABC切替、濁点・半濁点・小文字、句読点、削除、空白、改行、azooKeyによるオフラインかな漢字変換。

かなはキーボード内の未確定バッファに表示され、候補または「変換 / 確定」で現在の入力欄へ入ります。変換時に他アプリの文章を削除しません。未確定のまま外部操作でキーボードを閉じたり入力先を変えたりした場合、その未確定文字は破棄されます。先に確定してください。

## IPA

GitHub Actionsの「Build unsigned iOS IPA」でmacOS/XcodeによるRelease実機ビルドを作ります。成功した実行のArtifactsにある `GuruGuruKeyBoard-unsigned-ipa` の中に `.ipa` が入ります。

**無署名IPAです。ダウンロードするだけではiPhoneにインストールできません。** ホストアプリと内部のキーボード拡張を保持して、利用者自身の署名環境で両方を再署名してください。Appleの証明書・秘密鍵・パスワードはリポジトリに置かないでください。

インストール後: 設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 →「くるくる」。入力欄で地球儀から切り替えます。フルアクセスは不要です。

## Macでビルド

XcodeのSwift 6.1以降、iOS 16以降、XcodeGenが必要です。

```sh
brew install xcodegen
bash scripts/build_ipa.sh
```

署名して実機でRunする場合は `xcodegen generate` でプロジェクトを生成して開き、アプリと拡張の両方に自分のTeamと一意なBundle IDを設定してください。

## 検証

```sh
python3 -m unittest discover -s scripts -p 'test_*.py' -v
swift test -c release
python3 scripts/validate_ipa.py build/GuruGuruKeyBoard-unsigned.ipa
```

Swiftのテストは実際の辞書による「にほん→日本」「とうきょう→東京」、空入力、リセット、かな候補を確認します。IPA検査ではZIP整合性、ARM64実行ファイル、iPhoneOS、キーボード拡張、辞書、署名ファイル不在を確認します。実機操作テストとは別です。

## 依存関係と制限

AzooKeyKanaKanjiConverterは安定版 `0.11.2` に固定しています。Zenzaiと学習は無効。署名環境やApp Store配布手続きは含みません。パスワード欄などOSが許可しない入力欄では利用できません。高度な文節編集、予測学習、数字・記号専用レイアウトは未実装です。

第三者のライセンス文はビルド時に依存ソースから収集し、アプリ内の `ThirdPartyLicenses` に同梱します。
