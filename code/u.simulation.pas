unit u.simulation;

interface
  uses
    u.simcfg,
    u.map,
    u.cell,
    u.ants,
    px.vec2d;


type
  ///<summary>Main class that dictates whats happend in the world of ants.
  /// Creates and contains the Ants and map.
  ///</summary>
  TSimulation = class
    private
      //destructive zone
      fAntsToRemove :TAntList;
      fSomethingToDestroy :boolean;
    public
      ants  :TAntPack;
      map   :TMap;
      constructor create;
      destructor Destroy;override;
      procedure init;
      procedure finalize;
      procedure update;
      procedure DestructionTime;
      ///<<summary>The algorithm based on pheromones that does the magic</summary>
      procedure phero_algorithm;
      procedure draw;

      procedure AddAnts( count :integer );overload;
      procedure AddAnts( count :integer; const posg:TVec2di);overload;
      procedure DeleteAnts( count :integer );overload;
      procedure DeleteAnts( posg :TVec2di );overload;
      procedure RemoveAnt( ant :PAnt);
  end;
var
  sim :TSimulation;
implementation

{ TSimulation }

procedure TSimulation.init;
var
  i:integer;
begin
  randomize;
  cellFactory.init;
  map.init;
  ants.Init;
  ants.addNewAndInit(cfg.numAnts, lrOwner);
  //add all ants to 0,0 grid array; this avoid future validations
  for i := 0 to ants.items.Count-1 do
  begin
    map.grid[0,0].antsArray_add( ants.items.List[i] );
  end;

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
  i := frameTimer.time mod cfg.antLogicFrameSkip;
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
        //ant.headTo( myInterestSeen.where);
        ant.dirWishTo( myInterestSeen.where );
        ant.dirWishDuration := 150;
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
    inc( i, cfg.antLogicFrameSkip );
  end;
end;

procedure TSimulation.RemoveAnt(ant: PAnt);
begin
  //schedule to remove and free;
  if not fAntsToRemove.Contains(ant) then
  begin
    fAntsToRemove.Add(ant);
    fSomethingToDestroy := true;
  end;
end;

procedure TSimulation.update;
begin
  map.update;
  ants.update;
  ants.solveCollisions( map.getPassLevel );
  map.detectAntCellEvents( ants );
  phero_Algorithm;
  if fSomethingToDestroy then
  begin
    DestructionTime;
    fSomethingToDestroy := false;
  end;
  frameTimer.nextFrame;
end;

procedure TSimulation.AddAnts(count: integer);
var
  newAnts :TAntList;
  i: Integer;
begin
  newAnts := TAntList.Create;
  ants.addNewAndInit(count, lrOwner, newAnts);
  for i := 0 to newAnts.Count-1 do
  begin
    map.grid[0,0].antsArray_add( newAnts.List[i] );
  end;
  newAnts.Free;
end;

procedure TSimulation.AddAnts(count: integer; const posg: TVec2di);
var
  newAnts :TAntList;
  i: Integer;
begin
  if map.CheckInGrid(posg.x, posg.y, 1) then
  begin
    newAnts := TAntList.Create;
    ants.addNewAndInit(count, lrOwner, newAnts);
    for i := 0 to newAnts.Count-1 do
    begin
      map.grid[0, 0].antsArray_add( newAnts.List[i] );
      newAnts.List[i].pos.x := posg.x * cfg.mapCellSize + random(cfg.mapCellSize);
      newAnts.List[i].pos.y := posg.y * cfg.mapCellSize + random(cfg.mapCellSize);
    end;
    newAnts.Free;
  end;
end;

constructor TSimulation.create;
begin
  map := TMap.Create;
  ants := TAntPack.Create;
  ants.antOwner := true;

  fAntsToRemove := TAntList.Create;
  fSomethingToDestroy := false;
end;

procedure TSimulation.DeleteAnts(count: integer);
var
  i :integer;
begin
  //this is not that simple
  if ants.items.Count < count then count := ants.items.Count;
  for i := 0  to count-1 do
  begin
    RemoveAnt( ants.items.List[ ants.items.Count - i - 1] );
  end;
end;

procedure TSimulation.DeleteAnts(posg: TVec2di);
var
  i:integer;
begin
  if map.CheckInGrid(posg.x, posg.y, 1) then
  begin
    for i := 0 to map.grid[posg.x, posg.y].antsCount-1 do
    begin
      removeAnt( map.grid[posg.x, posg.y].ants[i] );
    end;
  end;
end;

destructor TSimulation.Destroy;
begin
  map.Free;
  ants.Free;
  fAntsToRemove.Free;
  inherited;
end;

procedure TSimulation.DestructionTime;
var
  ant :PAnt;
  i :integer;
begin
  //ants
  for i := 0  to fAntsToRemove.Count-1 do
  begin
    ant := fAntsToRemove.List[i];
    map.removeAnt(ant);
    ant.owner.removeAnt(ant, lrOwner );
    // ant.owner.items.dele
  end;
  fAntsToRemove.clear;
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
