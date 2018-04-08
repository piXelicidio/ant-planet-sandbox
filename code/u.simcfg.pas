unit u.simcfg;
//defaults, globals, (fight against hardcoding)...
interface

uses px.vec2d;

const
  CFG_MaxScanDirs = 8; //Max Index of scan directions of cell neibors..

type
  TPt = record
    x,y :integer;
  end;

const
  //to help to scan the grid, steps to check middle and all 8 neibors of a cell in 0,0
  CFG_GridScan :array[0..CFG_MaxScanDirs] of
    TPt =( (x: 0; y: 0),
           (x:-1; y:-1),
           (x: 0; y:-1),
           (x: 1; y:-1),
           (x:-1; y: 0),
           (x: 1; y: 0),
           (x:-1; y: 1),
           (x: 0; y: 1),
           (x: 1; y: 1) ) ;

type

  PSimCfg = ^TSimCfg;
  TSimCfg = record
    windowW  :integer;
    windowH  :integer;
    numAnts  :integer;
    antMaxSpeed :single;
    antErratic :single;
    antAccel :single;
    antRadialScanNum :integer;
    mapW  :integer;
    mapH  :integer;
    mapCellSize :integer;
  end;

var
  cfg           :TSimCfg;
  simFrameTime  :integer;

implementation

initialization

  with cfg do
  begin
    windowW := 1280;
    windowH := 720;
    numAnts := 300;
    antMaxSpeed := 1.2;
    antErratic := 0.2;
    antAccel := 0.1;
    antRadialScanNum := 16;
    mapW := 18;
    mapH := 10;
    mapCellSize := 64;
  end;
  simFrameTime := 0;
finalization
end.
