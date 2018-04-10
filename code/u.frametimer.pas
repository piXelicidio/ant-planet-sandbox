unit u.frametimer;

interface

type
  TFrameTimer = class
    fTime : integer;
  public
    constructor create;
    destructor Destroy;override;
    procedure nextFrame;
    property time:integer read fTime;
  end;

implementation

{ TFrameTimer }

constructor TFrameTimer.create;
begin
  fTime := 0;
end;

destructor TFrameTimer.Destroy;
begin

  inherited;
end;

procedure TFrameTimer.nextFrame;
begin
  inc(fTime);
end;

end.
