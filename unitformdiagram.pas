unit UnitFormDiagram;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, ExtDlgs, ButtonPanel, EditBtn, Spin,
  PrintersDlgs, UnitTetraPlotCore,Printers,math,Translations, Menus;

type

  { TFormDiagram }

  TFormDiagram = class(TForm)
    ButtonSaveImage: TButton;
    ButtonLeft: TButton;
    ButtonPrintImage: TButton;
    ButtonUp: TButton;
    ButtonDown: TButton;
    ButtonRight: TButton;
    Label1: TLabel;
    MenuItem21: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem31: TMenuItem;
    MenuItem32: TMenuItem;
    MenuItem34: TMenuItem;
    MenuItem41: TMenuItem;
    MenuItem42: TMenuItem;
    MenuItem43: TMenuItem;
    MenuItemPresets: TMenuItem;
    PaintBoxDiagram: TPaintBox;
    Panel1: TPanel;
    PopupMenuDiagram: TPopupMenu;
    PrintDialogDiagram: TPrintDialog;
    SavePictureDialogDiagram: TSavePictureDialog;
    SpinEditRotationAngle: TSpinEdit;
    procedure ButtonDownClick(Sender: TObject);
    procedure ButtonLeftClick(Sender: TObject);
    procedure ButtonPrintImageClick(Sender: TObject);
    procedure ButtonRightClick(Sender: TObject);
    procedure ButtonSaveImageClick(Sender: TObject);
    procedure ButtonUpClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemPresetClick(Sender: TObject);
    procedure MenuItemPresetsClick(Sender: TObject);
    procedure PaintBoxDiagramMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxDiagramMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBoxDiagramMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxDiagramMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure PaintBoxDiagramPaint(Sender: TObject);
    procedure PaintBoxDiagramResize(Sender: TObject);
    procedure DrawDiagram;//PaintBoxに図を再描画する
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  FormDiagram: TFormDiagram;
  Bitmap:TBitmap;
  //マウスによる図回転用の変数
  Rotating:Boolean;
  PreX,PreY:Integer;

const
  //最近接の文字をどれだけ大きくするかの係数 (0で変化なし、1で2倍)
  FontSizeZoomWithDistance=0.5;

implementation

uses UnitFormMain;

{ TFormDiagram }

procedure TFormDiagram.FormCloseQuery(Sender: TObject; var CanClose: boolean);
//FormDiagramが閉じられようとしたとき。最小化する。
begin
  CanClose:=FALSE;
  Self.WindowState:=wsMinimized;
end;

procedure TFormDiagram.ButtonLeftClick(Sender: TObject);
begin
  TetraSystem.RotateView(TetraSystem.VY,SpinEditRotationAngle.Value);
  DrawDiagram;
end;

procedure TFormDiagram.ButtonPrintImageClick(Sender: TObject);
//図の印刷
var
  Zoom:Double;
begin
  if PrintDialogDiagram.Execute then begin
    Printer.Title:='TetraPlot';
    Zoom:=min(Printer.PageHeight/Bitmap.Height,Printer.PageWidth/Bitmap.Width);
    Printer.BeginDoc;
    TetraSystem.DrawDiagram(Printer.Canvas,Printer.PageWidth,Printer.PageHeight,Zoom,FormMain.CheckBoxSmallTetrahedron.Checked,ifthen(FormMain.CheckBoxChangeFontSizeWithDistance.Checked,FontSizeZoomWithDistance));
    Printer.EndDoc;
  end;
end;

procedure TFormDiagram.ButtonDownClick(Sender: TObject);
begin
  TetraSystem.RotateView(TetraSystem.VX,-SpinEditRotationAngle.Value);
  DrawDiagram;
end;

procedure TFormDiagram.ButtonRightClick(Sender: TObject);
begin
  TetraSystem.RotateView(TetraSystem.VY,-SpinEditRotationAngle.Value);
  DrawDiagram;
end;

procedure TFormDiagram.ButtonSaveImageClick(Sender: TObject);
//図の保存
var
  //MF:TlmfImage;  //保存用メタファイル
  //MFCanvas:TlmfCanvas;
  MFStream:TFileStream;
  JPG:TJPEGImage;//保存用JPEG
  PNG:TPortableNetworkGraphic; //保存用PNG
begin
  //画像保存ダイアログを表示
  if Not(SavePictureDialogDiagram.Execute) then exit;
  if ExtractFileExt(SavePictureDialogDiagram.FileName)='.bmp' then begin
    Bitmap.SaveToFile(SavePictureDialogDiagram.FileName);
  end;
  if ExtractFileExt(SavePictureDialogDiagram.FileName)='.png' then begin
    PNG := TPortableNetworkGraphic.Create;
    try
      PNG.Assign(Bitmap);
      PNG.SaveToFile(SavePictureDialogDiagram.FileName);
    finally
      PNG.Free;
    end;
  end;
  if ExtractFileExt(SavePictureDialogDiagram.FileName)='.jpg' then begin
    JPG := TJPEGImage.Create;
    try
      JPG.Assign(Bitmap);
      JPG.SaveToFile(SavePictureDialogDiagram.FileName);
    finally
      JPG.Free;
    end;
  end;
  {if ExtractFileExt(SavePictureDialogDiagram.FileName)='.emf' then begin
    MF := TlmfImage.Create;
    MF.Clear;
    MF.Width:=Bitmap.Width;
    MF.Height:=Bitmap.Height;
    MFCanvas:=TlmfCanvas.Create(MF);
    TetraSystem.DrawDiagram(TCanvas(MFCanvas),MF.Width,MF.Height);
    try
      MFStream:=TFileStream.Create(UTF8ToSys(SavePictureDialogDiagram.FileName),fmCreate);
      MF.SaveToStream(MFStream);
    finally
      MFStream.Free;
      MF.Free;
    end;
  end;}
end;

procedure TFormDiagram.ButtonUpClick(Sender: TObject);
begin
  TetraSystem.RotateView(TetraSystem.VX,SpinEditRotationAngle.Value);
  DrawDiagram;
end;

procedure TFormDiagram.FormCreate(Sender: TObject);
//ウィンドウ生成時
begin
  Bitmap:=TBitmap.Create;
  Bitmap.PixelFormat:=pf32bit;
  PaintBoxDiagram.Canvas.CopyMode:=cmSrcCopy;
  PaintBoxDiagramResize(Sender);
  Rotating:=FALSE;
  //メニューのキャプション作成
  MenuItem12.Caption:=rsAxis+'1 - '+rsAxis+'2';
  MenuItem13.Caption:=rsAxis+'1 - '+rsAxis+'3';
  MenuItem14.Caption:=rsAxis+'1 - '+rsAxis+'4';
  MenuItem21.Caption:=rsAxis+'2 - '+rsAxis+'1';
  MenuItem23.Caption:=rsAxis+'2 - '+rsAxis+'3';
  MenuItem24.Caption:=rsAxis+'2 - '+rsAxis+'4';
  MenuItem31.Caption:=rsAxis+'3 - '+rsAxis+'1';
  MenuItem32.Caption:=rsAxis+'3 - '+rsAxis+'2';
  MenuItem34.Caption:=rsAxis+'3 - '+rsAxis+'4';
  MenuItem41.Caption:=rsAxis+'4 - '+rsAxis+'1';
  MenuItem42.Caption:=rsAxis+'4 - '+rsAxis+'2';
  MenuItem43.Caption:=rsAxis+'4 - '+rsAxis+'3';
end;

procedure TFormDiagram.MenuItemPresetClick(Sender: TObject);
//プリセットされた角度に視線ベクトルを合わす
begin
  with TetraSystem do begin
    if Sender=TObject(MenuItem12) then RotateToPresetAngle(Axis[0],Axis[1]);
    if Sender=TObject(MenuItem13) then RotateToPresetAngle(Axis[0],Axis[2]);
    if Sender=TObject(MenuItem14) then RotateToPresetAngle(Axis[0],Axis[3]);
    if Sender=TObject(MenuItem21) then RotateToPresetAngle(Axis[1],Axis[0]);
    if Sender=TObject(MenuItem23) then RotateToPresetAngle(Axis[1],Axis[2]);
    if Sender=TObject(MenuItem24) then RotateToPresetAngle(Axis[1],Axis[3]);
    if Sender=TObject(MenuItem31) then RotateToPresetAngle(Axis[2],Axis[0]);
    if Sender=TObject(MenuItem32) then RotateToPresetAngle(Axis[2],Axis[1]);
    if Sender=TObject(MenuItem34) then RotateToPresetAngle(Axis[2],Axis[3]);
    if Sender=TObject(MenuItem41) then RotateToPresetAngle(Axis[3],Axis[0]);
    if Sender=TObject(MenuItem42) then RotateToPresetAngle(Axis[3],Axis[1]);
    if Sender=TObject(MenuItem43) then RotateToPresetAngle(Axis[3],Axis[2]);
  end;
  DrawDiagram;
end;

procedure TFormDiagram.MenuItemPresetsClick(Sender: TObject);
begin

end;

procedure TFormDiagram.PaintBoxDiagramMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//PaintBox上でマウスの左ボタンが押されたとき
begin
  if Not(Button=mbLeft) then exit;
      //回転モードに入る
      Rotating:=TRUE;
      PreX:=X;
      PreY:=Y;
end;

procedure TFormDiagram.PaintBoxDiagramMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
  //PaintBox上でマウスが動いたとき
  var dx, dy:integer;
begin
  if Rotating=FALSE then exit;
  {if (GetKeyState(VK_LBUTTON) and $8000)=0 then
  begin
    Rotating:=FALSE;
    exit;
  end;}
  if Not(ssLeft in Shift) then begin
    Rotating:=FALSE;
    exit;
  end;
  //回転させる
  dx:=X-PreX;
  dy:=Y-PreY;
  PreX:=X;
  PreY:=Y;
  if dx<>0 then begin
    TetraSystem.RotateView(TetraSystem.VY,-dx/TetraSystem.TetrahedronWidth*90);
  end;
  if dy<>0 then begin
    TetraSystem.RotateView(TetraSystem.VX,-dy/TetraSystem.TetrahedronHeight*90);
  end;
  //描画
  DrawDiagram;
end;

procedure TFormDiagram.PaintBoxDiagramMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
//マウスボタンが離されたとき
begin
  if Button=mbLeft then begin;
    //回転モードが終わったことを図に反映するため再描画
    Rotating:=FALSE;
    DrawDiagram;
  end;
end;

procedure TFormDiagram.PaintBoxDiagramMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
  //マウスのホイールが回されたとき
begin
  If (ssCtrl in Shift) Then begin
    //なぜかLazarusではCtrlキーが反映されない
    If WheelDelta>0 Then ButtonRightClick(Sender);
    If WheelDelta<0 Then ButtonLeftClick(Sender);
  end else begin
    If WheelDelta>0 Then ButtonUpClick(Sender);
    If WheelDelta<0 Then ButtonDownClick(Sender);
  end;
end;




procedure TFormDiagram.PaintBoxDiagramPaint(Sender: TObject);
//PaintBox描画時
begin
  PaintBoxDiagram.Canvas.Draw(0,0,Bitmap);
end;





procedure TFormDiagram.PaintBoxDiagramResize(Sender: TObject);
//図の領域がサイズ変更されたとき
begin
  Bitmap.Width:=PaintBoxDiagram.ClientWidth;
  Bitmap.Height:=PaintBoxDiagram.ClientHeight;
  TetraSystem.DrawDiagram(Bitmap.Canvas,Bitmap.Width,Bitmap.Height,1,FormMain.CheckBoxSmallTetrahedron.Checked,ifthen(FormMain.CheckBoxChangeFontSizeWithDistance.Checked,FontSizeZoomWithDistance));
end;

procedure TFormDiagram.DrawDiagram;
//PaintBoxに図を再描画する
begin
  if Rotating then TetraSystem.EmphasizeTopmostAxis:=TRUE else TetraSystem.EmphasizeTopmostAxis:=FALSE;
  TetraSystem.DrawDiagram(Bitmap.Canvas,Bitmap.Width,Bitmap.Height,1,FormMain.CheckBoxSmallTetrahedron.Checked,ifthen(FormMain.CheckBoxChangeFontSizeWithDistance.Checked,FontSizeZoomWithDistance));
  PaintBoxDiagram.Canvas.Draw(0,0,Bitmap);
end;






initialization
  {$I unitformdiagram.lrs}

end.

