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
  ants.addNewAndInit(cfg.numAnts, map.HiddenCell, lrOwner);
end;

procedure TSimulation.phero_algorithm;
var
  i :integer;
  ant :PAnt;
  interest :TAntInterests;
  currGrid :PMapData;
begin
  for i := 0 to ants.items.Count-1 do
  begin
    //update pheromone info in map;
    ant := ants.items.List[i];
    currGrid := @map.grid[ ant.gridPos.x, ant.gridPos.y ];
    for interest := Low(TAntInterests) to High(TAntInterests) do
    begin
      if currGrid.pheromInfo.seen[ interest ].frameTime < ant.LastTimeSeen[ interest ] then
      begin
        currGrid.pheromInfo.seen[ interest ].frameTime := ant.LastTimeSeen[ interest ];
        currGrid.pheromInfo.seen[ interest ].where := ant.oldestPositionStored^;
      end;
    end;
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
