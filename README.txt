【成田空港から離陸する国際線飛行機の航路軌跡を3D地球モデル上に可視化】

Excel:		成田空港の離陸状況を書き出したExcelファイルを格納
Java:		Excelファイルを読み込み、有効データ抽出
libraries:	Processing外部ライブラリ
Processing:	メインプログラム


■本プログラムでは日本語を扱うので、Processing本体での設定が必要となる。

日本語設定の手順
1. 「File」→「Preferences」
2. 「Editor and Console font」で日本語表示可能なフォントを選択(ex. MSゴシック)
3. 「Use smooth text in editor window」にチェック
4. 「Enable complex text input」にチェック


■外部ライブラリを複数使用しているので、ライブラリを追加する必要がある。

ライブラリ追加の手順
1. 本プログラム添付の「libraries」フォルダの中身を、動作させるProcessing本体の「libraries」フォルダに移動