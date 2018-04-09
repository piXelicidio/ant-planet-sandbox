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

procedure TSimulation.update;
begin
  map.update;
  ants.update;
  ants.solveCollisions( map.getPassLevel );
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
