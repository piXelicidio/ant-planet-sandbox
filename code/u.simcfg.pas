unit u.simcfg;
//defaults, globals, types (fight against hardcoding)...
interface

uses px.vec2d, u.frameTimer;

const
  CFG_MaxScanDirs = 8; //Max Index of scan directions of cell neibors..

type

  TCellTypes = (ctFood, ctCave, ctGrass, ctBlock, ctGround); //ctBlock and ctGround don't need class
  //add more ant interests between ctFood and ctCave;
  TAntInterests = ctFood..ctCave;

const
  //to help to scan the grid, steps to check middle and all 8 neibors of a cell in 0,0
  CFG_GridScan :array[0..CFG_MaxScanDirs] of
    TVec2di =  ( (x: 0; y: 0),
                 (x:-1; y:-1),
                 (x: 0; y:-1),
                 (x: 1; y:-1),
                 (x:-1; y: 0),
                 (x: 1; y: 0),
                 (x:-1; y: 1),
                 (x: 0; y: 1),
                 (x: 1; y: 1) ) ;

  CFG_passLevelGround = 0;
  CFG_passLevelBlock = 1;
  CFG_passLevelOut = high(integer);

  CFG_antPositionMemorySize = 15;

type

  PSimCfg = ^TSimCfg;
  TSimCfg = record
    windowW  :integer;
    windowH  :integer;
    screenLogicalHight :integer;
    numAnts  :integer;
    numDebugAnts :integer;
    antMaxSpeed :single;
    antErratic :single;
    antAccel :single;
    antRadialScanNum :integer;
    mapW  :integer;
    mapH  :integer;
    mapCellSize :integer;
    debugPheromones :boolean;
    antLogicFrameSkip :integer;
    camMaxZoom :single;
    camMinZoom :single;
  end;

var
  cfg           :TSimCfg;
  frameTimer    :TFrameTimer;

implementation

initialization

  with cfg do
  begin
    windowW := 1280;
    windowH := 720;
    screenLogicalHight := 1080;
    numAnts := 10000;
    numDebugAnts := 3;
    antMaxSpeed := 1.2;
    antErratic := 0.18;
    antAccel := 0.1;
    antRadialScanNum := 16;
    antLogicFrameSkip := 3;   //value to skip ants from checking the pheromones path algorithm
    mapW := 20;
    mapH := 12;
    mapCellSize := 64;
    debugPheromones := false;
    camMaxZoom := 2;
    camMinZoom := 0.5;
  end;

  frameTimer := TFrameTimer.create;
finalization
  frameTimer.Free;
end.
