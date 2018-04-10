unit u.simulation;

interface
  uses
    u.simcfg,
    u.map,
    u.cell,
    u.ants;


type
  TSimulation = class
    public
      ants  :TAntPack;
      map   :TMap;
      constructor create;
      destructor Destroy;override;
      procedure init;
      procedure finalize;
      procedure update;
      procedure phero_algorithm;
      procedure draw;
  end;
var
  sim :TSimulation;
implementation

{ TSimulation }

procedure TSimulation.init;
begin
  cellFactory.init;
  map.init;
  ants.Init;
  ants.addNewAndInit(cfg.numAnts, lrOwner);
end;

procedure TSimulation.phero_algorithm;
var
  i :integer;
  ant :PAnt;
  interest :TAntInterests;
  myInterestSeen :PSeen;
  currGrid :PMapData;
  pheromInfo :PPheromInfo;
  scan: Integer;
begin
  //for i := 0 to ants.items.Count-1 do
  i := 0;
  while (i < ants.items.Count) do
  begin
    ant := ants.items.List[i];
    currGrid := @map.grid[ ant.gridPos.x, ant.gridPos.y ];

    //scan neibour grids for best pheromoes info
    for scan := 0 to High(CFG_GridScan) do
    begin
      pheromInfo := @map.grid[ ant.gridPos.x + CFG_GridScan[scan].x, ant.gridPos.y + CFG_GridScan[scan].x ].pheromInfo;
      myInterestSeen := @pheromInfo.seen[ ant.lookingFor ];
      if myInterestSeen.frameTime > ant.maxTimeSeen_MyTarget then
      begin
        ant.maxTimeSeen_MyTarget := myInterestSeen.frameTime;
        ant.headTo( myInterestSeen.where);
      end;
    end;

    //update pheromone info in map;
    for interest := Low(TAntInterests) to High(TAntInterests) do
    begin
      if currGrid.pheromInfo.seen[ interest ].frameTime < ant.LastTimeSeen[ interest ] then
      begin
        currGrid.pheromInfo.seen[ interest ].frameTime := ant.LastTimeSeen[ interest ];
        currGrid.pheromInfo.seen[ interest ].where := ant.oldestPositionStored^;
      end;
    end;
    //
    inc(i);
    i := i + random( cfg.antLogicFrameSkip );
  end;
end;

procedure TSimulation.update;
begin
  map.update;
  ants.update;
  ants.solveCollisions( map.getPassLevel );
  map.detectAntCellEvents( ants );
  phero_Algorithm;
  frameTimer.nextFrame;
end;

constructor TSimulation.create;
begin
  map := TMap.Create;
  ants := TAntPack.Create;
  ants.antOwner := true;
end;

destructor TSimulation.Destroy;
begin
  map.Free;
  ants.Free;
  inherited;
end;

procedure TSimulation.draw;
begin
  map.draw;
  ants.draw;
end;

procedure TSimulation.finalize;
begin
  map.finalize;
  cellFactory.finalize;
end;

initialization
  sim := TSimulation.Create;
finalization
  sim.Free;
end.
