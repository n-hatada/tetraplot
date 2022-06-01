unit UnitTetraPlotCore;

{20181114 なるべくカプセル化するようコードを改良したい。現状では、サンプルファイル
から系列を削除する際アクセス違反が発生する。}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math, DOM, XMLRead, XMLWrite, FileUtil, contnrs;

const
  //nMaxSeries = 1000;
  //nMaxComposition = 1000;
  //図の余白
  LMargin = 50;
  RMargin = 50;
  TMargin = 50;
  BMargin = 50;
  //シンボルの種類
  stCircle = 1;
  stRectangle = 2;
  //線の接続モードの種類  (20151005追加)
  lcmSingleLine = 1;
  lcmPairs = 2;
  lcmRoundRobin = 3;

type //3D Vector
  V3D = record
    X, Y, Z: double;
    Name: string;
  end;

type //4D Vector
  V4D = record
    Name: string;
    CoordVals: array[0..3] of double; //Coordinate values
  end;

type //2D Vector
  V2D = record
    X, Y: double;
  end;

type //Series class (系列クラス)

  { TSeries }

  TSeries = class(TObject)
  private
    FOwnerTetraSystem: TObject;//このクラスを保有しているTTetraPlotクラス
  public
    Name: string;//系列名
    RawComp4D: array of V4D;//生組成リスト(StringGridの内容)
    Comp3D: array of V3D;//3次元空間(world)に変換された組成座標
    nComposition: integer; //要素数
    Visible: boolean; //描画するかどうかを設定するフラグ

    //シンボルの書式
    SymbolVisible: boolean;
    SymbolType: integer;
    SymbolSize: integer;
    SymbolFillColor: TColor;
    SymbolEdgeColor: TColor;
    //シンボル間を結ぶ直線の書式
    LineVisible: boolean;
    LineWidth: integer;
    LineColor: TColor;
    LineClose: boolean;
    LineConnectionMode: integer; //接続モード20151005追加
    //組成ラベルについて
    CompLabelVisible: boolean;
    CompLabelSize: integer;
    constructor Create(AOwnerTetraSystem: TObject);
    procedure GetComp3D; //4次元の生組成から3次元座標に変換
    procedure ClearData; //系列の情報を破棄する
    procedure AddComposition(const tName: string; const X, Y, Z, W: double);
    //新しい組成点を追加する
  end;

type //System class

  { TTetraSystem }

  TTetraSystem = class(TObject)
  private
    //系列リスト
    FSeriesList: TFPObjectList;
    ////3次元空間(world)の点座標をView座標に変換した際の、Z座標値(手前に向かう座標)を返す
    function ConvWorldToViewZ(Src: V3D): double;
    function GetNumOfSeries: integer;
    function GetSeries(i: integer): TSeries;
  public
    VX, VY, VZ: V3D; //View Vector (World座標で視点座標軸を表したベクトル)
    Axis: array[0..3] of V3D; //4元系の座標軸
    EmphasizeTopmostAxis: boolean;
    //最前の頂点を強調するかどうかを示すフラグ
    //軸タイトルについて
    AxisTitleVisible: boolean;
    AxisTitleSize: integer;
    //実際の四面体が収まる幅と高さを記録
    TetrahedronWidth, TetrahedronHeight: integer;

    property Series[i: integer]: TSeries read GetSeries;//系列リスト
    property nSeries: integer read GetNumOfSeries; //系列数
    constructor Create;//Initialization
    function AddSeries: boolean;//系列を追加する関数
    procedure RemoveSeries(SeriesNum: integer);//系列を削除するプロシージャ
    procedure DrawDiagram(Canv: TCanvas; Width, Height: integer;
      SizeZoom: double; ShowSmallTetrahedron: boolean;
      FontSizeFactorWithDistance: double);
    //描画プロシージャ
    procedure ConvWorldToView(Src: V3D; var Rslt: V2D);
    //3次元空間(world)の点座標をView座標(2次元)に変換
    procedure RotateView(RotAxis: V3D; RotDeg: double);
    //View座標系を特定の軸RotAxisにそってRotDeg度だけ回転。回転軸は単位ベクトルであることを要求する。
    procedure SaveData(Filename: string); //データを保存する
    procedure OpenData(Filename: string); //データを開く
    //World座標におけるVFrontベクトルが画面の手前に向くように、VUpベクトルが画面の
    //うえを向くように視点座標軸を設定するプロシージャ
    procedure RotateToPresetAngle(const VFront, VUp: V3D);
    //20151113 座標軸の順序交換プロシージャ
    procedure TryExchangeAxes(const AxisNum1, AxisNum2: integer);
    //20181116 系列の順序交換プロシージャ
    procedure TryExchangeSeries(const SeriesNum1, SeriesNum2: integer);
  end;

//三次元ベクトルを単位ベクトル化するプロシージャ
procedure NormalizeV3D(var tempV3D: V3D);
//外積を返すプロシージャ
procedure OP(V1, V2: V3D; var VResult: V3D);


implementation
//三次元ベクトルを単位ベクトル化するプロシージャ
procedure NormalizeV3D(var tempV3D: V3D);
var
  k: double;
begin
  with tempV3D do
  begin
    k := sqrt(X * X + Y * Y + Z * Z);
    if k = 0 then
      exit;
    X := X / k;
    Y := Y / k;
    Z := Z / k;
  end;
end;
//外積を返すプロシージャ
procedure OP(V1, V2: V3D; var VResult: V3D);
begin
  with VResult do
  begin
    X := V1.Y * V2.Z - V1.Z * V2.Y;
    Y := V1.Z * V2.X - V1.X * V2.Z;
    Z := V1.X * V2.Y - V1.Y * V2.X;
  end;
end;

{ TTetraSystem }

constructor TTetraSystem.Create;
begin
  //最前頂点強調off
  EmphasizeTopmostAxis := False;
  //その他表示の設定
  AxisTitleSize := 15;
  AxisTitleVisible := True;
  //Initialization of View Vectors
  with VX do
  begin
    X := 1;
    Y := 0;
    Z := 0;
  end;
  with VY do
  begin
    X := 0;
    Y := 1;
    Z := 0;
  end;
  with VZ do
  begin
    X := 0;
    Y := 0;
    Z := 1;
  end;
  //Initialization of axes
  with Axis[0] do
  begin
    X := -1;
    Y := -1;
    Z := -1;
  end;
  with Axis[1] do
  begin
    X := -1;
    Y := 1;
    Z := 1;
  end;
  with Axis[2] do
  begin
    X := 1;
    Y := -1;
    Z := 1;
  end;
  with Axis[3] do
  begin
    X := 1;
    Y := 1;
    Z := -1;
  end;
  //系列クラスの生成
  FSeriesList := TFPObjectList.Create(True);
end;

function TTetraSystem.AddSeries: boolean;
  //系列を追加する関数。成功すればTRUE,失敗すればFALSEが返る
begin
  Result := False;
  FSeriesList.Add(TSeries.Create(Self));
  Result := True;
end;

procedure TTetraSystem.RemoveSeries(SeriesNum: integer);
//系列を削除
begin
  try
    FSeriesList.Delete(SeriesNum);
  except
  end;
end;

procedure TTetraSystem.DrawDiagram(Canv: TCanvas; Width, Height: integer;
  SizeZoom: double; ShowSmallTetrahedron: boolean; FontSizeFactorWithDistance: double);
//図を描画するプロシージャ(SizeZoomはフォントサイズ等を何倍にするか指定する係数）
//FontSizeFactorWithDistanceは、0ならフォントサイズを変えない。
//0以上なら、View座標におけるZ値が大きい(視点に近い)ほどフォントサイズを大きくする
//1なら、最接近文字の大きさが2倍、最遠の文字の大きさが0になる。
var
  i, j, k: integer;
  //View座標系での最大座標、最小座標を記録する
  MaxX, MaxY, MinX, MinY, MaxZ, tempZ: double;
  //View座標
  tV2D1, tV2D2: V2D;
  AxisView: array[0..3] of V2D;//View座標での四面体頂点のX,Y値
  AxisViewZ: array[0..3] of double;
  //View座標での四面体頂点のZ値 (こちらに向かう側がプラス)
  //Screen座標
  TP: array[0..3] of TPoint;
  //Screen座標に変換するための係数
  Zoom: double;
  //一時的に内積を格納
  tIP: double;
  Origin: TPoint;//view座標の原点をScreen座標で表す
  TopmostAxisNum: integer; //もっとも手前にある座標軸(頂点)の番号
  SmallTetraColor: TColor;

  procedure ViewToScr(Src: V2D; var Rslt: TPoint);
  //View座標からScreen座標への変換
  begin
    Rslt.x := floor(Src.X * Zoom) + Origin.x;
    Rslt.y := floor(Src.Y * (-Zoom)) + Origin.y;
  end;

begin
  //-----前準備-----
  //View座標系での最大座標、最小座標を記録する
  MaxX := 0;
  MinX := 0;
  MaxY := 0;
  MinY := 0;
  MaxZ := 0;
  for i := 0 to 3 do
  begin
    ConvWorldToView(Axis[i], AxisView[i]);
    MaxX := Max(AxisView[i].X, MaxX);
    MaxY := Max(AxisView[i].Y, MaxY);
    MinX := Min(AxisView[i].X, MinX);
    MinY := Min(AxisView[i].Y, MinY);
    AxisViewZ[i] := ConvWorldToViewZ(Axis[i]);
    if AxisViewZ[i] > MaxZ then
    begin
      MaxZ := AxisViewZ[i];
      TopmostAxisNum := i;
    end;
  end;
  //Screen座標へ変換するための定数を算出
  Zoom := Min((Width - (LMargin + RMargin) * SizeZoom) / (MaxX - MinX),
    (Height - (BMargin + TMargin) * SizeZoom) / (MaxY - MinY));
  Origin.x := trunc(-Zoom * (MaxX + MinX) / 2 +
    (Width - (LMargin + RMargin) * SizeZoom) / 2 + LMargin * SizeZoom);
  Origin.y := trunc(Zoom * (MaxY + MinY) / 2 +
    (Height - (TMargin + BMargin) * SizeZoom) / 2 + TMargin * SizeZoom);
  TetrahedronWidth := trunc(Zoom * (MaxX - MinX));
  TetrahedronHeight := trunc(Zoom * (MaxY - MinY));
  //-----描画開始-----
  //図を白塗り
  Canv.Brush.Style := bsSolid;
  Canv.Brush.Color := clWhite;
  Canv.FillRect(0, 0, Width - 1, Height - 1);
  //組成データのプロット
  for i := 0 to nSeries - 1 do
  begin
    //可視状態に設定されていない系列はスキップ
    if not (Series[i].Visible) then
      continue;
    //Lineを書く
    if (Series[i].LineVisible and (Series[i].nComposition > 1)) then
    begin
      //Pen,Brushの設定
      Canv.Pen.Style := psSolid;
      Canv.Pen.Color := Series[i].LineColor;
      Canv.Pen.Width := Trunc(Series[i].LineWidth * SizeZoom);
      //線の接続モードにより場合分け
      case Series[i].LineConnectionMode of
        lcmSingleLine, lcmPairs:
          //一筆書き, または2点1組で線を引いていくとき
        begin
          //一点目を変換
          ConvWorldToView(Series[i].Comp3D[0], tV2D1);
          ViewToScr(tV2D1, TP[0]);
          for j := 0 to Series[i].nComposition - 1 do
          begin
            //最後の点から最初の点に戻る線の処理
            if j = Series[i].nComposition - 1 then

            begin
              if (Series[i].LineClose = False) or
                (Series[i].LineConnectionMode <> lcmSingleLine) then
                Break;
            end;
            //ひとつ前の点TP[0]をTP[1]にコピー
            TP[1].x := TP[0].x;
            TP[1].y := TP[0].y;
            //新たな点を座標変換
            ConvWorldToView(Series[i].Comp3D[(j + 1) mod Series[i].nComposition], tV2D1);
            ViewToScr(tV2D1, TP[0]);
            //線を引く
            if (Series[i].LineConnectionMode = lcmPairs) and ((j mod 2) = 1) then
              continue;
            Canv.Line(TP[0], TP[1]);
          end;
        end;
        lcmRoundRobin://総当たり接続の時
        begin
          for j := 0 to Series[i].nComposition - 2 do
          begin
            //始点を座標変換
            ConvWorldToView(Series[i].Comp3D[j], tV2D1);
            ViewToScr(tV2D1, TP[0]);
            for k := j + 1 to Series[i].nComposition - 1 do
            begin
              //終点を座標変換
              ConvWorldToView(Series[i].Comp3D[k], tV2D2);
              ViewToScr(tV2D2, TP[1]);
              //線を引く
              Canv.Line(TP[0], TP[1]);
            end;
          end;
        end;
      end;
    end;
    //Symbolのプロット
    if Series[i].SymbolVisible then
    begin
      //とりあえずのペンの設定
      Canv.Pen.Style := psSolid;
      Canv.Pen.Color := Series[i].SymbolEdgeColor;
      Canv.Pen.Width := Trunc(1 * SizeZoom);
      //とりあえずブラシの設定
      Canv.Brush.Style := bsSolid;
      Canv.Brush.Color := Series[i].SymbolFillColor;
      for j := 0 to Series[i].nComposition - 1 do
      begin
        ConvWorldToView(Series[i].Comp3D[j], tV2D1);
        ViewToScr(tV2D1, TP[0]);
        //とりあえずプロット
        if Series[i].SymbolType = stCircle then
        begin
          //円でプロット
          Canv.EllipseC(TP[0].x, TP[0].y, Trunc(Series[i].SymbolSize * SizeZoom),
            Trunc(Series[i].SymbolSize * SizeZoom));
        end
        else
        begin
          if Series[i].SymbolType = stRectangle then
            //四角でプロット
            Canv.Rectangle(TP[0].x - Trunc(Series[i].SymbolSize * SizeZoom),
              TP[0].y - Trunc(Series[i].SymbolSize * SizeZoom), TP[0].x +
              Trunc(Series[i].SymbolSize * SizeZoom), TP[0].y +
              Trunc(Series[i].SymbolSize * SizeZoom));
        end;

      end;
    end;
  end;
  for i := 0 to nSeries - 1 do
  begin
    //可視状態に設定されていない系列はスキップ
    if not (Series[i].Visible) then
      continue;

    //組成ラベルの表示
    if Series[i].CompLabelVisible then
    begin
      //とりあえずブラシの設定
      //ブラシを透明に
      Canv.Brush.Style := bsClear;
      //Canv.Font.Size:=Trunc(Series[i].CompLabelSize*SizeZoom);
      //Canv.Font.Size := Series[i].CompLabelSize;
      for j := 0 to Series[i].nComposition - 1 do
      begin
        ConvWorldToView(Series[i].Comp3D[j], tV2D1);
        ViewToScr(tV2D1, TP[0]);
        Canv.Font.Size := Series[i].CompLabelSize +
          trunc(Series[i].CompLabelSize * FontSizeFactorWithDistance *
          ConvWorldToViewZ(Series[i].Comp3D[j]) / 1.732);
        //TextOut
        Canv.TextOut(TP[0].x, TP[0].y, Series[i].Comp3D[j].Name);
      end;
    end;
  end;

  //ブラシを透明に
  Canv.Brush.Style := bsClear;
  //フォントの設定
  //Canv.Font.Size:=Trunc(AxisTitleSize*SizeZoom);
  //Canv.Font.Size := AxisTitleSize;
  //座標軸の描画
  Canv.Pen.Color := clBlack;
  Canv.Pen.Width := Trunc(1 * SizeZoom);
  for i := 0 to 3 do
  begin
    //ConvWorldToView(Axis[i], tV2D1);
    ViewToScr(AxisView[i], TP[0]);
    for j := i + 1 to 3 do
    begin
      ViewToScr(AxisView[j], TP[1]);
      Canv.Line(TP[0], TP[1]);
    end;
    if AxisTitleVisible then
    begin
      //軸タイトルの表示
      if (EmphasizeTopmostAxis and (TopmostAxisNum = i)) then
        Canv.Font.Bold := True;
      Canv.Font.Size := AxisTitleSize + trunc(AxisTitleSize *
        FontSizeFactorWithDistance * AxisViewZ[i] / 1.732);
      Canv.TextOut(TP[0].x, TP[0].y, Axis[i].Name);
      if (EmphasizeTopmostAxis and (TopmostAxisNum = i)) then
        Canv.Font.Bold := False;
    end;
  end;
  //ガイド用のミニ四面体を表示
  if ShowSmallTetrahedron then
  begin
    Origin.x := Trunc(LMargin * 0.567 * SizeZoom);
    Origin.y := Trunc(Height - BMargin * 0.567 * SizeZoom);
    Zoom := min(LMargin, TMargin) / 4 * SizeZoom;
    //注：3次元の頂点ベクトルの長さはルート3
    Canv.Pen.Color := clBlack;
    Canv.Pen.Width := Trunc(1 * SizeZoom);
    Canv.Brush.Style := bsSolid;
    SmallTetraColor := clBlue;
    for i := 0 to 3 do
    begin
      //各頂点が向こう側を向いているかどうか調べる
      if AxisViewZ[i] < 0 then
      begin
        //頂点が向こう側を向いているとき、それ以外の頂点から作られる三角形を表示する
        for j := 0 to 2 do
        begin
          ViewToScr(AxisView[(i + 1 + j) mod 4], TP[j]);
        end;
        TP[3].x := TP[0].x;
        TP[3].y := TP[0].y;
        //面の塗り色を決める。光線は左上方向からで、View座標において(1,-1,-1)ベクトルとする。
        //これと、View座標における頂点ベクトル（三角形に含まれない)の内積をとり、大きいほど明るくする
        //それぞれ長さルート3のベクトルなので、単位ベクトル相当に内積を規格化する
        tIP := (AxisView[i].X - AxisView[i].Y - AxisViewZ[i]) / 3;
        Canv.Brush.Color := RGBToColor(trunc(Red(SmallTetraColor) /
          2 * (1 - tIP) + 255 / 2 * (1 + tIP)),
          trunc(Green(SmallTetraColor) / 2 * (1 - tIP) + 255 / 2 * (1 + tIP)),
          trunc(Blue(SmallTetraColor) / 2 * (1 - tIP) + 255 / 2 * (1 + tIP)));
        Canv.Polygon(TP);
      end;
    end;
  end;
end;

{ TSeries }


constructor TSeries.Create(AOwnerTetraSystem: TObject);
begin
  FOwnerTetraSystem := AOwnerTetraSystem;
  nComposition := 0;
  Name := 'New Series';
  //表示の設定
  SymbolVisible := True;
  SymbolSize := 3;
  SymbolType := stCircle;
  SymbolEdgeColor := clRed;
  SymbolFillColor := clWhite;
  LineVisible := False;
  LineColor := clRed;
  LineWidth := 1;
  LineClose := False;
  LineConnectionMode := lcmSingleLine;
  CompLabelSize := 10;
  CompLabelVisible := False;
end;

procedure TSeries.GetComp3D;
//4次元の生組成データから3次元空間の座標データに変換する
var
  Ctr: integer;
  NormFactor: double;//規格化因子
begin
  for Ctr := 0 to nComposition - 1 do
  begin
    //規格化因子を計算
    with RawComp4D[Ctr] do
    begin
      NormFactor := CoordVals[0] + CoordVals[1] + CoordVals[2] + CoordVals[3];
    end;
    //4D -> 3D変換
    with TTetraSystem(FOwnerTetraSystem) do
    begin
      Comp3D[Ctr].Name := RawComp4D[Ctr].Name;
      Comp3D[Ctr].X := RawComp4D[Ctr].CoordVals[0] * Axis[0].X +
        RawComp4D[Ctr].CoordVals[1] * Axis[1].X + RawComp4D[Ctr].CoordVals[2] *
        Axis[2].X + RawComp4D[Ctr].CoordVals[3] * Axis[3].X;
      Comp3D[Ctr].X := Comp3D[Ctr].X / NormFactor;
      Comp3D[Ctr].Y := RawComp4D[Ctr].CoordVals[0] * Axis[0].Y +
        RawComp4D[Ctr].CoordVals[1] * Axis[1].Y + RawComp4D[Ctr].CoordVals[2] *
        Axis[2].Y + RawComp4D[Ctr].CoordVals[3] * Axis[3].Y;
      Comp3D[Ctr].Y := Comp3D[Ctr].Y / NormFactor;
      Comp3D[Ctr].Z := RawComp4D[Ctr].CoordVals[0] * Axis[0].Z +
        RawComp4D[Ctr].CoordVals[1] * Axis[1].Z + RawComp4D[Ctr].CoordVals[2] *
        Axis[2].Z + RawComp4D[Ctr].CoordVals[3] * Axis[3].Z;
      Comp3D[Ctr].Z := Comp3D[Ctr].Z / NormFactor;
    end;
  end;
end;

procedure TSeries.ClearData;
//系列の情報を初期化する
begin
  nComposition := 0;
end;

procedure TSeries.AddComposition(const tName: string; const X, Y, Z, W: double);
//新しい組成点を追加する
begin
  nComposition := nComposition + 1;
  SetLength(Comp3D, nComposition);
  SetLength(RawComp4D, nComposition);
  RawComp4D[nComposition - 1].Name := tName;
  RawComp4D[nComposition - 1].CoordVals[0] := X;
  RawComp4D[nComposition - 1].CoordVals[1] := Y;
  RawComp4D[nComposition - 1].CoordVals[2] := Z;
  RawComp4D[nComposition - 1].CoordVals[3] := W;
end;

procedure TTetraSystem.ConvWorldToView(Src: V3D; var Rslt: V2D);
//3次元空間(world)の点座標をView座標に変換
begin
  Rslt.X := VX.X * Src.X + VX.Y * Src.Y + VX.Z * Src.Z;
  Rslt.Y := VY.X * Src.X + VY.Y * Src.Y + VY.Z * Src.Z;
end;

function TTetraSystem.ConvWorldToViewZ(Src: V3D): double;
  //3次元空間(world)の点座標をView座標に変換した際の、Z座標値(手前に向かう座標)を返す
begin
  Result := VZ.X * Src.X + VZ.Y * Src.Y + VZ.Z * Src.Z;
end;

function TTetraSystem.GetSeries(i: integer): TSeries;
begin
  try
    Result := TSeries(FSeriesList.Items[i]);
  except
    Result := nil;
  end;
end;

function TTetraSystem.GetNumOfSeries: integer;
begin
  if Assigned(FSeriesList) then
    Result := FSeriesList.Count
  else
    Result := 0;
end;

procedure TTetraSystem.RotateView(RotAxis: V3D; RotDeg: double);
//View座標系を特定の軸RotAxisにそってRotDeg度だけ回転
//回転軸は単位ベクトルであることを要求する
var
  RACopy: V3D;
  q: double;//回転角をrad単位で格納
  CosThY, SinThY, CosThZ, SinThZ: double;
  tX, tY, tZ: double;
begin
  //回転軸を複製
  RACopy.X := RotAxis.X;
  RACopy.Y := RotAxis.Y;
  RACopy.Z := RotAxis.Z;
  //回転角をrad変換
  q := degtorad(RotDeg);
  //各基底ベクトルの回転は次の手順で行う
  //z軸まわりに角度-ThZだけ回転して回転軸をxz面に入れる
  //y軸まわりに角度-ThYだけ回転して回転軸をz軸と一致させる
  //z軸まわりに角度qだけ回転
  //y軸まわりに角度ThYだけ回転
  //z軸まわりに角度ThZだけ回転
  //回転角の算出
  CosThY := RACopy.Z;
  SinThY := sqrt(1 - CosThY * CosThY);
  if SinThY = 0 then
  begin
    CosThZ := 1;
    SinThZ := 0;
  end
  else
  begin
    CosThZ := RACopy.X / SinThY;
    SinThZ := RACopy.Y / SinThY;
  end;
  //View座標の各基底ベクトルを回転
  //VXを回転
  tX := (sin(q) * SinThY * SinThZ + (1 - cos(q)) * CosThY * SinThY * CosThZ) *
    VX.Z + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ - sin(q) * CosThY) *
    VX.Y + ((cos(q) - 1) * power(SinThY, 2) * power(SinThZ, 2) +
    (1 - cos(q)) * power(SinThY, 2) + cos(q)) * VX.X;
  tY := ((1 - cos(q)) * CosThY * SinThY * SinThZ - sin(q) * SinThY * CosThZ) *
    VX.Z + ((1 - cos(q)) * power(SinThY, 2) * power(SinThZ, 2) + cos(q)) *
    VX.Y + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ + sin(q) * CosThY) * VX.X;
  tZ := ((cos(q) - 1) * power(SinThY, 2) + 1) * VX.Z +
    ((1 - cos(q)) * CosThY * SinThY * SinThZ + sin(q) * SinThY * CosThZ) *
    VX.Y + ((1 - cos(q)) * CosThY * SinThY * CosThZ - sin(q) * SinThY * SinThZ) * VX.X;
  VX.X := tX;
  VX.Y := tY;
  VX.Z := tZ;
  //VYを回転
  tX := (sin(q) * SinThY * SinThZ + (1 - cos(q)) * CosThY * SinThY * CosThZ) *
    VY.Z + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ - sin(q) * CosThY) *
    VY.Y + ((cos(q) - 1) * power(SinThY, 2) * power(SinThZ, 2) +
    (1 - cos(q)) * power(SinThY, 2) + cos(q)) * VY.X;
  tY := ((1 - cos(q)) * CosThY * SinThY * SinThZ - sin(q) * SinThY * CosThZ) *
    VY.Z + ((1 - cos(q)) * power(SinThY, 2) * power(SinThZ, 2) + cos(q)) *
    VY.Y + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ + sin(q) * CosThY) * VY.X;
  tZ := ((cos(q) - 1) * power(SinThY, 2) + 1) * VY.Z +
    ((1 - cos(q)) * CosThY * SinThY * SinThZ + sin(q) * SinThY * CosThZ) *
    VY.Y + ((1 - cos(q)) * CosThY * SinThY * CosThZ - sin(q) * SinThY * SinThZ) * VY.X;
  VY.X := tX;
  VY.Y := tY;
  VY.Z := tZ;
  //VZを回転
  tX := (sin(q) * SinThY * SinThZ + (1 - cos(q)) * CosThY * SinThY * CosThZ) *
    VZ.Z + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ - sin(q) * CosThY) *
    VZ.Y + ((cos(q) - 1) * power(SinThY, 2) * power(SinThZ, 2) +
    (1 - cos(q)) * power(SinThY, 2) + cos(q)) * VZ.X;
  tY := ((1 - cos(q)) * CosThY * SinThY * SinThZ - sin(q) * SinThY * CosThZ) *
    VZ.Z + ((1 - cos(q)) * power(SinThY, 2) * power(SinThZ, 2) + cos(q)) *
    VZ.Y + ((1 - cos(q)) * power(SinThY, 2) * CosThZ * SinThZ + sin(q) * CosThY) * VZ.X;
  tZ := ((cos(q) - 1) * power(SinThY, 2) + 1) * VZ.Z +
    ((1 - cos(q)) * CosThY * SinThY * SinThZ + sin(q) * SinThY * CosThZ) *
    VZ.Y + ((1 - cos(q)) * CosThY * SinThY * CosThZ - sin(q) * SinThY * SinThZ) * VZ.X;
  VZ.X := tX;
  VZ.Y := tY;
  VZ.Z := tZ;
  //20150325 回転操作の繰り返しによる誤差の蓄積を防ぐため、VX, VYを単位ベクトル
  //化し、VX x VY = VZとする
  NormalizeV3D(VX);
  NormalizeV3D(VY);
  OP(VX, VY, VZ);
  //もしかしたら誤差の蓄積でVX, VYが直交しなくなるかもしれないので、さらに
  //OP(VZ,VX,VY);
  //をしたほうがいいかもしれない。
end;

procedure TTetraSystem.SaveData(Filename: string);
//データを保存する
var
  Doc: TXMLDocument;//文書を格納する変数
  RootNode, DataNode, SeriesNode, CompNode: TDOMNode;//ノードを格納する変数
  i, j, k: integer;

  //ParentNodeの下に、TextNodeNameという名前でTextという内容の要素を追加する
  procedure CreateTextNodeFast(ParentNode: TDOMNode; TextNodeName, Text: string);
  var
    tNode: TDOMNode;
  begin
    tNode := Doc.CreateElement(TextNodeName);
    tNode.AppendChild(Doc.CreateTextNode(Text));
    //ParentNode.ChildNodes.Item[ParentNode.ChildNodes.Count].AppendChild(tNode);
    ParentNode.AppendChild(tNode);
  end;

begin
  //XML Creation
  Doc := TXMLDocument.Create;
  //"RootNode"要素を作成する
  RootNode := Doc.CreateElement('TetraPlotFile');
  //"RootNode"要素を"Doc"のルート要素として保存する
  Doc.Appendchild(RootNode);
  RootNode := Doc.DocumentElement;
  //"Data"ノード(要素)を作成する
  DataNode := Doc.CreateElement('Data');
  //"Data"ノードの属性に系列の数を設定する
  //TDOMElement(DataNode).SetAttribute('NumOfSeries', IntToStr(nSeries));

  //"Data"ノードをルート要素の下の要素として保存する
  RootNode.Appendchild(DataNode);

  //"Data"ノードの中に系列の数などを保存
  CreateTextNodeFast(DataNode, 'NumOfSeries', IntToStr(nSeries));
  CreateTextNodeFast(DataNode, 'AxisTitleVisible', BoolToStr(AxisTitleVisible));
  CreateTextNodeFast(DataNode, 'AxisTitleSize', IntToStr(AxisTitleSize));
  //軸のデータを保存
  for i := 0 to 3 do
  begin
    CreateTextNodeFast(DataNode, 'AxisTitle', Axis[i].Name);
  end;

  //系列のデータを順次保存
  for i := 0 to nSeries - 1 do
  begin
    //SeriesNodeを作成
    SeriesNode := Doc.CreateElement('Series');
    //SeriesNodeの下に属性を設定
    {TDOMElement(SeriesNode).SetAttribute('Title', Series[i].Name));//系列名
    TDOMElement(SeriesNode).SetAttribute('NumOfCompositions', IntToStr(Series[i].nComposition));//系列に属する組成データの個数
    TDOMElement(SeriesNode).SetAttribute('Visible', BoolToStr(Series[i].Visible));//表示状態}

    //SeriesNodeをDataNodeの下に保存する
    DataNode.AppendChild(SeriesNode);

    //SeriesNodeに情報を保存
    CreateTextNodeFast(SeriesNode, 'Title', Series[i].Name);//系列名;
    CreateTextNodeFast(SeriesNode, 'NumOfCompositions',
      IntToStr(Series[i].nComposition));
    //系列に属する組成データの個数
    CreateTextNodeFast(SeriesNode, 'Visible', BoolToStr(Series[i].Visible));
    //表示状態
    CreateTextNodeFast(SeriesNode, 'SymbolVisible', BoolToStr(Series[i].SymbolVisible));
    CreateTextNodeFast(SeriesNode, 'SymbolType', IntToStr(Series[i].SymbolType));
    CreateTextNodeFast(SeriesNode, 'SymbolSize', IntToStr(Series[i].SymbolSize));
    CreateTextNodeFast(SeriesNode, 'SymbolEdgeColor',
      ColorToString(Series[i].SymbolEdgeColor));
    CreateTextNodeFast(SeriesNode, 'SymbolFillColor',
      ColorToString(Series[i].SymbolFillColor));
    CreateTextNodeFast(SeriesNode, 'LineVisible', BoolToStr(Series[i].LineVisible));
    CreateTextNodeFast(SeriesNode, 'LineWidth', IntToStr(Series[i].LineWidth));
    CreateTextNodeFast(SeriesNode, 'LineColor', ColorToString(Series[i].LineColor));
    CreateTextNodeFast(SeriesNode, 'LineClose', BoolToStr(Series[i].LineClose));
    CreateTextNodeFast(SeriesNode, 'LineConnectionMode',
      IntToStr(Series[i].LineConnectionMode));
    CreateTextNodeFast(SeriesNode, 'CompLabelVisible',
      BoolToStr(Series[i].CompLabelVisible));
    CreateTextNodeFast(SeriesNode, 'CompLabelSize', IntToStr(Series[i].CompLabelSize));

    //組成データを順次保存
    for j := 0 to Series[i].nComposition - 1 do
    begin
      //CompNodeを作成
      CompNode := Doc.CreateElement('Composition');
      //CompNodeをSeriesNodeの下に保存する
      SeriesNode.AppendChild(CompNode);
      //CompNodeの下に情報を保存
      CreateTextNodeFast(CompNode, 'Label', Series[i].RawComp4D[j].Name);//組成名;
      for k := 0 to 3 do
        CreateTextNodeFast(CompNode, 'Coord',
          FloatToStr(Series[i].RawComp4D[j].CoordVals[k]));//組成
    end;
  end;
  //XMLファイルに書き込み
  //WriteXMLFile(Doc, UTF8ToSys(Filename));
  WriteXMLFile(Doc, Filename);
  //メモリ解放
  Doc.Free;
end;

procedure TTetraSystem.OpenData(Filename: string);
//データを開く
var
  Doc: TXMLDocument;//文書を格納する変数
  Child: TDOMNode;//ノードを格納する変数
  AxisNum, SeriesNum, CompNum, CValNum: integer;
  //何個目のデータを読み取っているか記録

  //Compositionノードを解釈するプロシージャ
  procedure ReadCompNode(tmpNode: TDOMNode);
  var
    tmpChild: TDOMNode;
  begin
    if CompNum > TSeries(FSeriesList.Last).nComposition - 1 then
      exit;
    CValNum := 0;
    //子ノードを読みに行く
    tmpChild := tmpNode.FirstChild;
    while Assigned(tmpChild) do
    begin
      if ((tmpChild.NodeName = 'Title') or (tmpChild.NodeName = 'Label')) then
      begin
        //Titleノードの場合
        try
          TSeries(FSeriesList.Last).RawComp4D[CompNum].Name :=
            tmpChild.FirstChild.NodeValue;
        except
          TSeries(FSeriesList.Last).RawComp4D[CompNum].Name := '';
        end;
      end;
      if tmpChild.NodeName = 'Coord' then
      begin
        //Coordノードの場合
        TSeries(FSeriesList.Last).RawComp4D[CompNum].CoordVals[CValNum] :=
          StrToFloat(tmpChild.FirstChild.NodeValue);
        CValNum := CValNum + 1;
      end;
      tmpChild := tmpChild.NextSibling;
    end;
  end;

  //Seriesノードを解釈するプロシージャ
  procedure ReadSeriesNode(tmpNode: TDOMNode);
  var
    tmpChild: TDOMNode;
  begin
    //if SeriesNum > nSeries - 1 then
    //  exit;
    CompNum := 0;
    //子ノードを読みに行く
    tmpChild := tmpNode.FirstChild;
    while Assigned(tmpChild) do
    begin
      //----------------------
      if tmpChild.NodeName = 'Title' then
      begin
        //Titleノードの場合
        try
          TSeries(FSeriesList.Last).Name := tmpChild.FirstChild.NodeValue;
        except
          TSeries(FSeriesList.Last).Name := '';
        end;
      end;
      //----------------------
      if tmpChild.NodeName = 'NumOfCompositions' then
      begin
        //NumOfSeriesノードの場合
        TSeries(FSeriesList.Last).nComposition :=
          StrToInt(tmpChild.FirstChild.NodeValue);
        SetLength(TSeries(FSeriesList.Last).RawComp4D,
          TSeries(FSeriesList.Last).nComposition);
        SetLength(TSeries(FSeriesList.Last).Comp3D,
          TSeries(FSeriesList.Last).nComposition);
      end;
      //----------------------
      if tmpChild.NodeName = 'Visible' then
      begin
        //NumOfSeriesノードの場合
        TSeries(FSeriesList.Last).Visible := StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'SymbolVisible' then
      begin
        TSeries(FSeriesList.Last).SymbolVisible :=
          StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'SymbolType' then
      begin
        TSeries(FSeriesList.Last).SymbolType := StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'SymbolSize' then
      begin
        TSeries(FSeriesList.Last).SymbolSize := StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'SymbolEdgeColor' then
      begin
        TSeries(FSeriesList.Last).SymbolEdgeColor :=
          StringToColor(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'SymbolFillColor' then
      begin
        TSeries(FSeriesList.Last).SymbolFillColor :=
          StringToColor(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'LineVisible' then
      begin
        TSeries(FSeriesList.Last).LineVisible :=
          StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'LineWidth' then
      begin
        TSeries(FSeriesList.Last).LineWidth := StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'LineColor' then
      begin
        TSeries(FSeriesList.Last).LineColor :=
          StringToColor(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'LineClose' then
      begin
        TSeries(FSeriesList.Last).LineClose := StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'LineConnectionMode' then
      begin
        TSeries(FSeriesList.Last).LineConnectionMode :=
          StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'CompLabelVisible' then
      begin
        TSeries(FSeriesList.Last).CompLabelVisible :=
          StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'CompLabelSize' then
      begin
        TSeries(FSeriesList.Last).CompLabelSize :=
          StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      //----------------------
      if tmpChild.NodeName = 'Composition' then
      begin
        //Compositionノードの場合
        ReadCompNode(tmpChild);
        CompNum := CompNum + 1;
      end;
      //----------------------
      tmpChild := tmpChild.NextSibling;
    end;
    //4次元の生組成データを3D World座標に変換
    TSeries(FSeriesList.Last).GetComp3D;
  end;

  //Dataノードを解釈するプロシージャ
  procedure ReadDataNode(tmpNode: TDOMNode);
  var
    tmpChild: TDOMNode;
  begin
    //'Data'ノードの場合
    AxisNum := 0;
    SeriesNum := 0;
    //子ノードを読みに行く
    tmpChild := tmpNode.FirstChild;
    while Assigned(tmpChild) do
    begin
      if tmpChild.NodeName = 'AxisTitle' then
      begin
        //AxisTitleノードの場合
        try
          Axis[AxisNum].Name := tmpChild.FirstChild.NodeValue;
        except
          Axis[AxisNum].Name := '';
        end;
        AxisNum := AxisNum + 1;
      end;
      if tmpChild.NodeName = 'NumOfSeries' then
      begin
        //NumOfSeriesノードの場合
        //nSeries := StrToInt(tmpChild.FirstChild.NodeValue);
      end;
      if tmpChild.NodeName = 'AxisTitleVisible' then
      begin
        AxisTitleVisible := StrToBool(tmpChild.FirstChild.NodeValue);
      end;
      if tmpChild.NodeName = 'AxisTitleSize' then
      begin
        AxisTitleSize := StrToInt(tmpChild.FirstChild.NodeValue);
      end;

      if tmpChild.NodeName = 'Series' then
      begin
        //Seriesノードの場合
        FSeriesList.Add(TSeries.Create(Self));
        ReadSeriesNode(tmpChild);
        //SeriesNum := SeriesNum + 1;
      end;
      tmpChild := tmpChild.NextSibling;
    end;
  end;

begin
  //nSeries := 0;
  FSeriesList.Clear;
  //XML読み込み
  //XMLファイルを読み書きする際は、ファイル名の文字コード変換をしないとエラーになる
  //ReadXMLFile(Doc, UTF8ToSys(Filename));
  ReadXMLFile(Doc, Filename);
  //解釈
  Child := Doc.DocumentElement.FirstChild;
  while Assigned(Child) do
  begin
    if Child.NodeName = 'Data' then
      ReadDataNode(Child);
    Child := Child.NextSibling;
  end;

  //メモリ解放
  Doc.Free;
end;
//World座標におけるVFrontベクトルが画面の手前に向くように、VUpベクトルが画面の
//うえを向くように視点座標軸を設定するプロシージャ
procedure TTetraSystem.RotateToPresetAngle(const VFront, VUp: V3D);
var
  k: double;
begin
  //手前に向く軸の設定
  VZ.X := VFront.X;
  VZ.Y := VFront.Y;
  VZ.Z := VFront.Z;
  NormalizeV3D(VZ);
  k := -(VZ.Z * VZ.Z + VZ.Y * VZ.Y + VZ.X * VZ.X) /
    (VUp.Z * VZ.Z + VUp.Y * VZ.Y + VUp.X * VZ.X);
  //画面の上に向く軸の設定
  VY.X := VZ.X + k * VUp.X;
  VY.Y := VZ.Y + k * VUp.Y;
  VY.Z := VZ.Z + k * VUp.Z;
  NormalizeV3D(VY);
  OP(VY, VZ, VX);
end;

//座標軸の順序交換プロシージャ
procedure TTetraSystem.TryExchangeAxes(const AxisNum1, AxisNum2: integer);
var
  tempStr: string;
  tempDbl: double;
  i, j: integer;
begin
  if (Min(AxisNum1, AxisNum2) < 0) or (Max(AxisNum1, AxisNum2) > 3) then
    exit;
  //軸タイトルを入れ替える
  tempStr := Axis[AxisNum1].Name;
  Axis[AxisNum1].Name := Axis[AxisNum2].Name;
  Axis[AxisNum2].Name := tempStr;
  //全系列の座標を入れ替える
  for i := 0 to nSeries - 1 do
  begin
    with Series[i] do
    begin
      for j := 0 to nComposition - 1 do
      begin
        tempDbl := RawComp4D[j].CoordVals[AxisNum1];
        RawComp4D[j].CoordVals[AxisNum1] := RawComp4D[j].CoordVals[AxisNum2];
        RawComp4D[j].CoordVals[AxisNum2] := tempDbl;
      end;
      GetComp3D;
    end;
  end;
end;

procedure TTetraSystem.TryExchangeSeries(const SeriesNum1, SeriesNum2: integer);
begin
  try
    FSeriesList.Exchange(SeriesNum1, SeriesNum2);
  except

  end;
end;



end.
