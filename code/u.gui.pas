unit u.gui;

interface
  uses
    px.guiso,
    system.Classes,
    u.simcfg
    ;


type
  TAppGui = class
    private
    protected
      fMain :TGuisoScreen;
      fMainPanel :TGuisoPanel;

      fScreen :TGuisoScreen; //current screen;
    public
      lblFPS :TGuisoLabel;
      lblNumAnts :TGuisoLabel;
      radioTool :TGuisoRadioGroup;
      procedure init;
      constructor create;
      destructor Destroy;override;
      property screen:TGuisoScreen read fScreen;
  end;


implementation

{ TAppGui }

constructor TAppGui.create;
begin
  fMain := TGuisoScreen.create;
  fScreen := fMain;
end;

destructor TAppGui.Destroy;
begin
  fMain.free;
  inherited;
end;

procedure TAppGui.init;
var
  strs :TStringList;
begin
  //main;
  fMainPanel := TGuisoPanel.create;
  fMainPanel.setWH(120, 700 );
  fMain.addChild(fMainPanel);
  fMainPanel.setXY(0,0);

  lblFPS := TGuisoLabel.create;
  lblFPS.setWH(100, 20);
  lblFPS.TextAlignX := 0;
  fMainPanel.addChild(lblFPS, 0.5, 0);

  lblNumAnts := TGuisoLabel.create;
  lblNumAnts.TextAlignX := 0;
  fMainPanel.addChildBellow(lblNumAnts, lblFPS, true);

  strs := TStringList.Create;
  strs.Add('block');
  strs.Add('grass');
  strs.Add('cave');
  strs.Add('food');
  strs.Add('portal');
  strs.add('remove');
  radioTool := TGuisoRadioGroup.create(strs, fMainPanel.width-20, 30);
  fMainPanel.addChildBellow(radioTool, lblNumAnts);
end;

end.
