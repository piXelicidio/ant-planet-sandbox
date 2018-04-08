unit u.simulation;

interface
  uses
    u.simcfg,
    u.map,
    u.ants;

type
  TSimulation = class
    public
      ants  :TAntPack;
      map   :TMap;
      constructor create;
      destructor Destroy;override;
      procedure init;
      procedure update;
      procedure draw;
  end;
var
  sim :TSimulation;
implementation

{ TSimulation }

procedure TSimulation.init;
begin
  map.init;
  ants.Init;
  ants.addNewAndInit(cfg.numAnts, lrOwner);
end;


procedure TSimulation.update;
begin
  //map.update;
  ants.update;
  ants.solveCollisions( map.canPass );
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

initialization
  sim := TSimulation.Create;
finalization
  sim.Free;
end.
