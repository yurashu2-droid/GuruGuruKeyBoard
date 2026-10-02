# GuruGuruKeyBoard

iPhone用の、文字が流れるカスタム日本語キーボード。Googleの公式アプリではありません。

## ソースコード

実装・テスト・ビルド手順は **[build/ios-ipa ブランチ](https://github.com/yurashu2-droid/GuruGuruKeyBoard/tree/build/ios-ipa)** にあります。

SwiftUI / Custom Keyboard Extension / AzooKeyKanaKanjiConverter 0.11.2。日本語変換は端末内で行い、フルアクセスは要求しません。

## IPA

[GitHub Actions](https://github.com/yurashu2-droid/GuruGuruKeyBoard/actions) の `Build unsigned iOS IPA` を開き、成功した実行の Artifacts にある `GuruGuruKeyBoard-unsigned-ipa` をダウンロードしてください。ZIP内に `.ipa` と検査レポート・SHA256チェックサムが入ります。

**無署名IPAのため、ダウンロードだけではiPhoneにインストールできません。** インストールにはホストアプリと内蔵のキーボード拡張の両方を、利用者自身の署名環境で再署名する必要があります。

インストール後は「設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → くるくる」で有効にします。

実機での操作テストと、ビルド・変換の自動テストは別です。現在は試作版です。
