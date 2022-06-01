unit UnitFormMain;

//Ver1.0.1
//系列リストのチェックの有無にかかわらず組成ラベルが表示されるバグを修正

//Ver1.1.0　(2011/4/17)
//lprファイルにusesにDefaultTranslatorを追加
//また、ウィンドウのあるユニットのusesにTranslationsを追加
//オプションの国際化にチェックを入れ、多言語対応にした
//"Languages\TetraPlot.jp.po"に日本語の翻訳文字列を格納
//IDEから自動的にPOファイルに変更を適用したいときは、
//以前IDEで作成された"TetraPlot.po"を削除した後で
//IDEで"すべて構築"すると、"TetraPlot.po"が再作成されると同時に、
//"TetraPlot.jp.po"にも変更が追加される

//Ver1.2.0　(2011/4/17)
//図の上で右クリックすると、プリセット角度を選べるようにした
//また、コマンドラインパラメータで起動時に読み込むファイルを指定できるようにした。

//Ver1.2.1 (2015/3/25)
//回転操作を繰り返すと誤差の蓄積により図がおかしくなるのを修正するため
//TTetraSystem.RotateViewを修正

//Ver1.3.0 (2015/10/5)
//線を接続するモードを選択できるよう、機能拡張
//UnitFormMainとUnitTetraPlotCoreを更新

//Ver1.4.0 (2015/10/6)
//軸タイトルストリンググリッドで、複数選択を許可しないようにする
//軸の順序の入れ替え機能を追加する予定
//Up, Downボタンを押したときの処理は未実装
//また、座標データのストリンググリッドの行数をボタンで動的に増やすようにした。

//Ver1.5.0 (2016/1/19)
//座標データのストリンググリッドの行数をエクセルのように自動的に増やすようにした。
//各系列の座標データ数を無制限に。配列の要素数はその都度増減させることとした。
//また、一番左の列に行番号を表示するようにした。
//系列数を最大1000まで許容するようにした。

//Ver.1.6.0 (2018/11/16)
//系列数の上限を撤廃
//系列をFPObjectListを使用して管理するようにした。これでアクセス違反の心配は減るはず
//Lazarus 1.8.2ではUTF8関係の関数が削除されたようなので、各種関数名からUTF8をとった。
//あと、系列の順序を入れ替える機能をつけた
//あとは国際化のみ -> poeditでTetraPlot.jp.poを開き翻訳を確定して保存する
//系列や、座標軸の順序を入れ替えた後で、もとのアイテムの選択が維持されるようにした。
//頂点の前後が把握しやすいよう、小さい四面体を表示するようにした。

//Ver.1.7.0 (2018/11/19)
//距離に応じてフォントサイズを変調する機能を追加


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  Menus, StdCtrls, CheckLst, Grids, ExtCtrls, Spin, UnitTetraPlotCore,
  Math;

type

  { TFormMain }

  TFormMain = class(TForm)
    ButtonAddRows: TButton;
    ButtonAxisMoveDown: TButton;
    ButtonAddSeries: TButton;
    ButtonAxisMoveUp: TButton;
    ButtonRemoveSeries: TButton;
    ButtonSeriesMoveUp: TButton;
    ButtonSeriesMoveDown: TButton;
    CheckBoxChangeFontSizeWithDistance: TCheckBox;
    CheckBoxSmallTetrahedron: TCheckBox;
    CheckBoxLineClose: TCheckBox;
    CheckBoxAxisTitleVisible: TCheckBox;
    CheckBoxSymbolVisible: TCheckBox;
    CheckBoxLineVisible: TCheckBox;
    CheckBoxCompLabelVisible: TCheckBox;
    CheckListBoxSeries: TCheckListBox;
    ColorButtonEdgeColor: TColorButton;
    ColorButtonLineColor: TColorButton;
    ColorButtonFillColor: TColorButton;
    ComboBoxSymbolType: TComboBox;
    ComboBoxLineConnectionMode: TComboBox;
    EditSeriesTitle: TLabeledEdit;
    GroupBoxCompLabel: TGroupBox;
    GroupBoxLine: TGroupBox;
    GroupBoxSeriesDetails: TGroupBox;
    GroupBoxSeriesList: TGroupBox;
    GroupBoxAxisTitles: TGroupBox;
    GroupBoxSymbol: TGroupBox;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    MainMenuMain: TMainMenu;
    MenuItemSave: TMenuItem;
    MenuItemOpen: TMenuItem;
    MenuItemFile: TMenuItem;
    MenuItemAbout: TMenuItem;
    MenuItemHelp: TMenuItem;
    OpenDialogMain: TOpenDialog;
    SaveDialogMain: TSaveDialog;
    SpinEditSymbolSize: TSpinEdit;
    SpinEditLineWidth: TSpinEdit;
    SpinEditAxisFontSize: TSpinEdit;
    SpinEditCompLabelSize: TSpinEdit;
    StringGridAxisTitles: TStringGrid;
    StringGridCoordData: TStringGrid;
    procedure ButtonAddRowsClick(Sender: TObject);
    procedure ButtonAddSeriesClick(Sender: TObject);
    procedure ButtonAxisMoveDownClick(Sender: TObject);
    procedure ButtonAxisMoveUpClick(Sender: TObject);
    procedure ButtonRemoveSeriesClick(Sender: TObject);
    procedure ButtonSeriesMoveDownClick(Sender: TObject);
    procedure ButtonSeriesMoveUpClick(Sender: TObject);
    procedure CheckBoxAxisTitleVisibleChange(Sender: TObject);
    procedure CheckBoxChangeFontSizeWithDistanceChange(Sender: TObject);
    procedure CheckBoxCompLabelVisibleChange(Sender: TObject);
    procedure CheckBoxLineCloseChange(Sender: TObject);
    procedure CheckBoxLineVisibleChange(Sender: TObject);
    procedure CheckBoxSmallTetrahedronChange(Sender: TObject);
    procedure CheckBoxSymbolVisibleChange(Sender: TObject);
    procedure CheckListBoxSeriesClick(Sender: TObject);
    procedure ColorButtonEdgeColorColorChanged(Sender: TObject);
    procedure ColorButtonFillColorColorChanged(Sender: TObject);
    procedure ColorButtonLineColorColorChanged(Sender: TObject);
    procedure ComboBoxLineConnectionModeChange(Sender: TObject);
    procedure ComboBoxSymbolTypeChange(Sender: TObject);
    procedure EditSeriesTitleExit(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure SpinEditAxisFontSizeChange(Sender: TObject);
    procedure SpinEditCompLabelSizeChange(Sender: TObject);
    procedure SpinEditLineWidthChange(Sender: TObject);
    procedure SpinEditSymbolSizeChange(Sender: TObject);
    procedure StringGridAxisTitlesEditingDone(Sender: TObject);
    procedure StringGridAxisTitlesSelectCell(Sender: TObject;
      aCol, aRow: integer; var CanSelect: boolean);
    procedure StringGridCoordDataEditingDone(Sender: TObject);
  private
    procedure TryExchangeAxes(Sender: TObject; const AxisNum1, AxisNum2: integer);
    procedure TryExchangeSeries(Sender: TObject;
      const SeriesNumSelected, SeriesNumTarget: integer);
    function GetSelectedSeries: integer;
    procedure ShowAxisSettingsAndSeriesList;
    procedure OpenDataFile; //ファイルを開くプロシージャ
    { private declarations }
  public
    { public declarations }
  end;

var
  FormMain: TFormMain;
  TetraSystem: TTetraSystem;

resourcestring
  rsAxis = 'Axis';
  rsLabelOptional = 'Label (optional)';
  rsWarning = 'Warning';
  rsExceededMaxi = 'Exceeded maximum number of series!';
  rsQuitTetraPlo = 'Quit TetraPlot?';
  rsSeriesTitle = 'Series title';
  rsAboutTetraPl = 'About TetraPlot';
  rsExceededMaxi2 = 'Exceeded maximum number of coodinates! ';
  rsDoNotOverwri = 'Do not overwrite the file because some data can be lost. ';
  rsPleaseUseANe = 'Please use a newer version of TetraPlot.';

implementation

uses UnitFormDiagram;

{ TFormMain }


procedure TFormMain.StringGridAxisTitlesEditingDone(Sender: TObject);
//AxisTitleが編集されたとき
begin
  StringGridCoordData.Cells[2, 0] := StringGridAxisTitles.Cells[1, 0];
  StringGridCoordData.Cells[3, 0] := StringGridAxisTitles.Cells[1, 1];
  StringGridCoordData.Cells[4, 0] := StringGridAxisTitles.Cells[1, 2];
  StringGridCoordData.Cells[5, 0] := StringGridAxisTitles.Cells[1, 3];
  TetraSystem.Axis[0].Name := StringGridAxisTitles.Cells[1, 0];
  TetraSystem.Axis[1].Name := StringGridAxisTitles.Cells[1, 1];
  TetraSystem.Axis[2].Name := StringGridAxisTitles.Cells[1, 2];
  TetraSystem.Axis[3].Name := StringGridAxisTitles.Cells[1, 3];
  //図を更新
  FormDiagram.DrawDiagram;
end;

//軸タイトルストリンググリッドのセルが選択されたとき
//軸の順序入れ替えボタンの有効・無効を切り替える
procedure TFormMain.StringGridAxisTitlesSelectCell(Sender: TObject;
  aCol, aRow: integer; var CanSelect: boolean);
begin
  ButtonAxisMoveDown.Enabled := (aRow < 3);
  ButtonAxisMoveUp.Enabled := (aRow > 0);
end;

procedure TFormMain.StringGridCoordDataEditingDone(Sender: TObject);
//組成データが変更されたとき
var
  i, j: integer;
  SelNum: integer;
  TempVal: array[0..3] of double;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
    exit;
  //行データを調査し、有効なデータをTetraSystemに反映する
  TetraSystem.Series[SelNum].ClearData;
  for i := 1 to StringGridCoordData.RowCount - 1 do
  begin
    for j := 1 to 4 do
    begin
      TempVal[j - 1] := StrToFloatDef(StringGridCoordData.Cells[j + 1, i], 0);
    end;
    //行に座標データがない時は読み飛ばす
    if abs(TempVal[0]) + abs(TempVal[1]) + abs(TempVal[2]) + abs(TempVal[3]) = 0 then
      continue;
    //行に座標データがあるときはTetraSystemに反映する
    TetraSystem.Series[SelNum].AddComposition(StringGridCoordData.Cells[1, i],
      TempVal[0], TempVal[1], TempVal[2], TempVal[3]);
  end;
  TetraSystem.Series[SelNum].GetComp3D;
  //図を更新
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.FormCreate(Sender: TObject);
//**************************************
//ウィンドウ生成時
//**************************************
var
  i: integer;
begin
  //TetraSystemを生成
  TetraSystem := TTetraSystem.Create;
  //StringGridの列タイトルを設定
  StringGridAxisTitles.Cells[0, 0] := rsAxis + '1';
  StringGridAxisTitles.Cells[0, 1] := rsAxis + '2';
  StringGridAxisTitles.Cells[0, 2] := rsAxis + '3';
  StringGridAxisTitles.Cells[0, 3] := rsAxis + '4';
  StringGridAxisTitles.ColWidths[0] := 50;
  StringGridAxisTitles.ColWidths[1] := 150;
  StringGridCoordData.Cells[1, 0] := rsLabelOptional;
  //TLabeledEditのラベルの設定(なぜか自動的に翻訳されないので)
  EditSeriesTitle.EditLabel.Caption := rsSeriesTitle;
  //一応軸の初期設定を表示しておく
  ShowAxisSettingsAndSeriesList;
  //系列データを扱うコントロールを無効に
  GroupBoxSeriesDetails.Enabled := False;

  //コマンドラインで渡されたファイルを開く
  for i := 1 to Paramcount do
  begin
    if FileExists(ParamStr(i)) then
    begin
      OpenDialogMain.FileName := ParamStr(i);
      OpenDataFile;
      break;
    end;
  end;

end;

procedure TFormMain.ButtonAddSeriesClick(Sender: TObject);
//Addボタンクリック時（系列を追加する）
begin
  //系列の追加を試みる
  if TetraSystem.AddSeries then
  begin
    //追加に成功したとき
    CheckListBoxSeries.Items.Add(TetraSystem.Series[TetraSystem.nSeries - 1].Name);
    TetraSystem.Series[TetraSystem.nSeries - 1].Visible := True;
    CheckListBoxSeries.Checked[CheckListBoxSeries.Count - 1] := True;
  end;
end;

//"Add rows"ボタンが押されたとき
procedure TFormMain.ButtonAddRowsClick(Sender: TObject);
begin
  //20151118 stringgridの行数を調整
  StringGridCoordData.RowCount := StringGridCoordData.RowCount + 50;
end;


//軸を"Down"させるボタンを押したとき
procedure TFormMain.ButtonAxisMoveDownClick(Sender: TObject);
var
  AxisNumBefore, AxisNumAfter, i: integer;
begin
  //選択された軸番号と、交換対象の軸番号を取得
  for i := 0 to 3 do
  begin
    if StringGridAxisTitles.IsCellSelected[1, i] then
    begin
      AxisNumBefore := i;
      break;
    end;
  end;
  if AxisNumBefore=3 then exit;
  AxisNumAfter := AxisNumBefore + 1;
  TryExchangeAxes(Sender, AxisNumBefore, AxisNumAfter);
  StringGridAxisTitles.Col:=1;
  StringGridAxisTitles.Row:=AxisNumAfter;
  StringGridAxisTitles.SetFocus;
end;

//軸を"Up"させるボタンを押したとき
procedure TFormMain.ButtonAxisMoveUpClick(Sender: TObject);
var
  AxisNumBefore, AxisNumAfter, i: integer;
begin
  //選択された軸番号と、交換対象の軸番号を取得
  for i := 0 to 3 do
  begin
    if StringGridAxisTitles.IsCellSelected[1, i] then
    begin
      AxisNumBefore := i;
      break;
    end;
  end;
  if AxisNumBefore=0 then exit;
  AxisNumAfter := AxisNumBefore - 1;
  TryExchangeAxes(Sender, AxisNumBefore, AxisNumAfter);
  StringGridAxisTitles.Col:=1;
  StringGridAxisTitles.Row:=AxisNumAfter;
  StringGridAxisTitles.SetFocus;
end;

//軸を交換し、描画に反映するプロシージャ
procedure TFormMain.TryExchangeAxes(Sender: TObject; const AxisNum1, AxisNum2: integer);
var
  i: integer;
begin
  if (Min(AxisNum1, AxisNum2) >= 0) and (Max(AxisNum1, AxisNum2) <= 3) then
  begin
    //軸タイトルを入れ替える
    //全系列の座標を入れ替え
    TetraSystem.TryExchangeAxes(AxisNum1, AxisNum2);
    //ストリンググリッドのタイトル行を更新する
    for i := 0 to 3 do
    begin
      StringGridAxisTitles.Cells[1, i] := TetraSystem.Axis[i].Name;
      StringGridCoordData.Cells[i + 2, 0] := TetraSystem.Axis[i].Name;
    end;
  end;
  //系列が選択されているとき、その座標データの表示も更新する
  CheckListBoxSeriesClick(Sender);
  //図を更新する
  FormDiagram.DrawDiagram;
end;

//系列を交換し、描画に反映するプロシージャ
//呼び出す際、CheckListBoxSeriesでひとつの系列が選択状態にあることが前提
//交換後も同じ系列を選択状態にする。
//系列情報（座標など）の表示の更新は行わない。したがって、同じ系列が選択された状態を維持しないと、
//系列情報と選択された系列の整合がとれなくなってしまう。

procedure TFormMain.TryExchangeSeries(Sender: TObject;
  const SeriesNumSelected, SeriesNumTarget: integer);
begin
  if (Min(SeriesNumSelected, SeriesNumTarget) >= 0) and (Max(SeriesNumSelected, SeriesNumTarget) <=
    CheckListBoxSeries.Count - 1) then
  begin
    //系列を入れ替える
    TetraSystem.TryExchangeSeries(SeriesNumSelected, SeriesNumTarget);
    CheckListBoxSeries.Items.Exchange(SeriesNumSelected, SeriesNumTarget);
    //もともと選択されていた系列を選択
    CheckListBoxSeries.Selected[SeriesNumTarget]:=True;
    ButtonSeriesMoveUp.Enabled := (SeriesNumTarget > 0);
  ButtonSeriesMoveDown.Enabled := (SeriesNumTarget < CheckListBoxSeries.Count - 1);
  //図を更新する
  FormDiagram.DrawDiagram;
  end;

end;

procedure TFormMain.ButtonRemoveSeriesClick(Sender: TObject);
//Removeボタンクリック時(系列を削除する)
var
  SelNum: integer;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
    exit;
  //選択されたアイテムを削除する
  TetraSystem.RemoveSeries(SelNum);
  CheckListBoxSeries.Items.Delete(SelNum);
  //系列のデータのコントロールを無効に
  GroupBoxSeriesDetails.Enabled := False;
  EditSeriesTitle.Text := '';
  StringGridCoordData.Clean(1, 1, StringGridCoordData.ColCount - 1,
    StringGridCoordData.RowCount - 1, [gzNormal]);
  //図を更新
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ButtonSeriesMoveDownClick(Sender: TObject);
var
  SelNum: integer;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
    exit;
  TryExchangeSeries(Sender, SelNum, SelNum + 1);
end;

procedure TFormMain.ButtonSeriesMoveUpClick(Sender: TObject);
var
  SelNum: integer;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
    exit;
  TryExchangeSeries(Sender, SelNum, SelNum - 1);
end;

procedure TFormMain.CheckBoxAxisTitleVisibleChange(Sender: TObject);
begin
  if not (Assigned(Bitmap)) then
    exit;
  TetraSystem.AxisTitleVisible := CheckBoxAxisTitleVisible.Checked;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckBoxChangeFontSizeWithDistanceChange(Sender: TObject);
begin
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckBoxCompLabelVisibleChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].CompLabelVisible := CheckBoxCompLabelVisible.Checked;
  FormDiagram.DrawDiagram;

end;

procedure TFormMain.CheckBoxLineCloseChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].LineClose := CheckBoxLineClose.Checked;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckBoxLineVisibleChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].LineVisible := CheckBoxLineVisible.Checked;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckBoxSmallTetrahedronChange(Sender: TObject);
begin
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckBoxSymbolVisibleChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].SymbolVisible := CheckBoxSymbolVisible.Checked;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.CheckListBoxSeriesClick(Sender: TObject);
//系列リストがクリックされたとき
var
  i, j: integer;
  SelNum: integer;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
  begin
    //選択されていないとき
    GroupBoxSeriesDetails.Enabled := False;
    //EditSeriesTitle.Enabled:=FALSE;
    EditSeriesTitle.Text := '';
    //StringGridCoordData.Enabled:=FALSE;
    StringGridCoordData.Clean(1, 1, StringGridCoordData.ColCount - 1,
      StringGridCoordData.RowCount - 1, [gzNormal]);
    ButtonRemoveSeries.Enabled := False;
    ButtonSeriesMoveUp.Enabled := False;
    ButtonSeriesMoveDown.Enabled := False;
    exit;
  end;
  //------------選択されているとき------------
  GroupBoxSeriesDetails.Enabled := True;
  ButtonRemoveSeries.Enabled := True;
  ButtonSeriesMoveUp.Enabled := (SelNum > 0);
  ButtonSeriesMoveDown.Enabled := (SelNum < CheckListBoxSeries.Count - 1);

  //------------選択されたアイテムの情報を表示する---------
  //stringgridの内容を初期化
  StringGridCoordData.Clean(1, 1, StringGridCoordData.ColCount - 1,
    StringGridCoordData.RowCount - 1, [gzNormal]);
  //20151113 stringgridの行数を調整
  StringGridCoordData.RowCount :=
    Max(51, TetraSystem.Series[SelNum].nComposition + 1 + 10);
  //stringgridに反映
  for i := 0 to TetraSystem.Series[SelNum].nComposition - 1 do
  begin
    //20151113 stringgridの行数を超えてデータを読み込まないようにする
    if i + 1 > StringGridCoordData.RowCount - 1 then
    begin
      MessageDlg(rsWarning, rsExceededMaxi2 + rsDoNotOverwri + rsPleaseUseANe,
        mtWarning, [mbOK], 0);
      Break;
    end;
    StringGridCoordData.Cells[1, i + 1] := TetraSystem.Series[SelNum].RawComp4D[i].Name;
    for j := 0 to 3 do
    begin
      StringGridCoordData.Cells[j + 2, i + 1] :=
        FloatToStr(TetraSystem.Series[SelNum].RawComp4D[i].CoordVals[j]);
    end;
  end;
  //Series title
  EditSeriesTitle.Text := TetraSystem.Series[SelNum].Name;
  //Symbol
  CheckBoxSymbolVisible.Checked := TetraSystem.Series[SelNum].SymbolVisible;
  ComboBoxSymbolType.ItemIndex := TetraSystem.Series[SelNum].SymbolType - 1;
  SpinEditSymbolSize.Value := TetraSystem.Series[SelNum].SymbolSize;
  ColorButtonEdgeColor.ButtonColor := TetraSystem.Series[SelNum].SymbolEdgeColor;
  ColorButtonFillColor.ButtonColor := TetraSystem.Series[SelNum].SymbolFillColor;
  //Line
  CheckBoxLineVisible.Checked := TetraSystem.Series[SelNum].LineVisible;
  ComboBoxLineConnectionMode.ItemIndex :=
    TetraSystem.Series[SelNum].LineConnectionMode - 1;
  SpinEditLineWidth.Value := TetraSystem.Series[SelNum].LineWidth;
  ColorButtonLineColor.ButtonColor := TetraSystem.Series[SelNum].LineColor;
  CheckBoxLineClose.Checked := TetraSystem.Series[SelNum].LineClose;
  //CompLabel
  CheckBoxCompLabelVisible.Checked := TetraSystem.Series[SelNum].CompLabelVisible;
  SpinEditCompLabelSize.Value := TetraSystem.Series[SelNum].CompLabelSize;
  //-------------再描画
  //チェックボックスの状態を取得する
  TetraSystem.Series[SelNum].Visible := CheckListBoxSeries.Checked[SelNum];
  //チェックのON OFFが切り替えられたときのことを考え描画更新
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ColorButtonEdgeColorColorChanged(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].SymbolEdgeColor := ColorButtonEdgeColor.ButtonColor;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ColorButtonFillColorColorChanged(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].SymbolFillColor := ColorButtonFillColor.ButtonColor;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ColorButtonLineColorColorChanged(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].LineColor := ColorButtonLineColor.ButtonColor;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ComboBoxLineConnectionModeChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].LineConnectionMode :=
    ComboBoxLineConnectionMode.ItemIndex + 1;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ComboBoxSymbolTypeChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].SymbolType := ComboBoxSymbolType.ItemIndex + 1;
  FormDiagram.DrawDiagram;
end;



procedure TFormMain.EditSeriesTitleExit(Sender: TObject);
//系列タイトルが入力されたとき
var
  SelNum: integer;
  TempFlag: boolean;
begin
  //選択された系列アイテム番号を調査
  SelNum := GetSelectedSeries;
  if SelNum < 0 then
    exit;
  //TetraSystemと系列リストに反映
  TetraSystem.Series[SelNum].Name := EditSeriesTitle.Text;
  //なぜかCheckListBoxのテキストを変更するとチェックの状態が変更されてしまうので
  //Checkの状態を記録しておく
  TempFlag := CheckListBoxSeries.Checked[SelNum];
  CheckListBoxSeries.Items.Strings[SelNum] := EditSeriesTitle.Text;
  CheckListBoxSeries.Checked[SelNum] := TempFlag;
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
//ウィンドウが閉じようとされたとき
begin
  if MessageDlg('TetraPlot', rsQuitTetraPlo, mtConfirmation,
    [mbYes, mbCancel], 0) = mrYes then
    CanClose := True
  else
    CanClose := False;
end;

procedure TFormMain.MenuItemAboutClick(Sender: TObject);
//***************************************
//メニューのAboutクリック時
//***************************************
begin
  MessageDlg(rsAboutTetraPl, 'TetraPlot 1.7.0' + #13#10 + '(C) Naoyuki Hatada.',
    mtInformation, [mbOK], 0);
end;

procedure TFormMain.MenuItemOpenClick(Sender: TObject);
//***************************************
//メニューのOpenクリック時
//***************************************
begin
  if OpenDialogMain.Execute then
  begin
    OpenDataFile;
    //図を更新
    FormDiagram.DrawDiagram;
  end;
end;



procedure TFormMain.MenuItemSaveClick(Sender: TObject);
//***************************************
//メニューのSaveクリック時
//***************************************
begin
  if SaveDialogMain.Execute then
  begin
    TetraSystem.SaveData(SaveDialogMain.FileName);
  end;
end;

procedure TFormMain.SpinEditAxisFontSizeChange(Sender: TObject);
begin
  if not (Assigned(Bitmap)) then
    exit;
  TetraSystem.AxisTitleSize := SpinEditAxisFontSize.Value;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.SpinEditCompLabelSizeChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].CompLabelSize := SpinEditCompLabelSize.Value;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.SpinEditLineWidthChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].LineWidth := SpinEditLineWidth.Value;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.SpinEditSymbolSizeChange(Sender: TObject);
var
  SelNum: integer;
begin
  if not (Assigned(Bitmap)) then
    exit;
  SelNum := GetSelectedSeries;
  if SelNum = -1 then
    exit;
  TetraSystem.Series[SelNum].SymbolSize := SpinEditSymbolSize.Value;
  FormDiagram.DrawDiagram;
end;

procedure TFormMain.ShowAxisSettingsAndSeriesList;
//TetraSystemの軸設定および系列リストを画面上に表示するプロシージャ
var
  i: integer;
begin
  //Axis titles
  for i := 0 to 3 do
  begin
    StringGridAxisTitles.Cells[1, i] := TetraSystem.Axis[i].Name;
    StringGridCoordData.Cells[i + 2, 0] := TetraSystem.Axis[i].Name;
  end;
  CheckBoxAxisTitleVisible.Checked := TetraSystem.AxisTitleVisible;
  SpinEditAxisFontSize.Value := TetraSystem.AxisTitleSize;
  //Series List
  CheckListBoxSeries.Clear;
  for i := 0 to TetraSystem.nSeries - 1 do
  begin
    CheckListBoxSeries.Items.Add(TetraSystem.Series[i].Name);
    CheckListBoxSeries.Checked[CheckListBoxSeries.Count - 1] :=
      TetraSystem.Series[i].Visible;
  end;
  //選択されていない系列の座標データ表示が残らないよう、系列リストのクリックイベントを発生させておく
  CheckListBoxSeriesClick(nil);
end;

procedure TFormMain.OpenDataFile;
//データファイルを開くプロシージャ
begin
  //現在の情報を破棄
  StringGridAxisTitles.Clean(1, 0, 1, 3, [gzNormal]);
  GroupBoxSeriesDetails.Enabled := False;
  //EditSeriesTitle.Enabled:=FALSE;
  EditSeriesTitle.Text := '';
  //StringGridCoordData.Enabled:=FALSE;
  StringGridCoordData.Clean(1, 1, StringGridCoordData.ColCount - 1,
    StringGridCoordData.RowCount - 1, [gzNormal]);
  StringGridCoordData.Clean(2, 0, 5, 0, [gzNormal]);
  CheckListBoxSeries.Clear;
  TetraSystem.Free;
  //新たにTetraSystemクラスを生成
  TetraSystem := TTetraSystem.Create;
  //ファイルの読み込み
  TetraSystem.OpenData(OpenDialogMain.FileName);
  //データを画面に反映
  ShowAxisSettingsAndSeriesList;
end;

function TFormMain.GetSelectedSeries: integer;
  //選択されている系列番号を取得する。選択されていないときは-1を返す
var
  i: integer;
begin
  //選択されたアイテムがあるか調査
  if CheckListBoxSeries.SelCount = 0 then
  begin
    Result := -1;
    exit;
  end;
  //選択されたアイテム番号を調査
  for i := 0 to CheckListBoxSeries.Count - 1 do
  begin
    if CheckListBoxSeries.Selected[i] then
    begin
      Result := i;
      Break;
    end;
  end;
end;


initialization
  {$I unitformmain.lrs}

end.
