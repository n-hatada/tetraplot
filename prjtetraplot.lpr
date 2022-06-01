program prjtetraplot;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, UnitFormMain, Printer4Lazarus, unittetraplotcore,
  UnitFormDiagram, DefaultTranslator	//DefaultTranslatorを加えておけば、POファイルを探して自動的に翻訳してくれる
  { you can add units after this };




//{$IFDEF WINDOWS}{$R prjtetraplot.rc}{$ENDIF}

{$R *.res}

begin
  Application.Title:='TetraPlot';
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormDiagram, FormDiagram);
  Application.Run;
end.

