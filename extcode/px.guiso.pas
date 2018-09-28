unit px.guiso;
{
  Graphical
  User
  Interface for
  SDL2 with
  Object pascal Delphi

  by Denys Almaral
}
interface
uses
  system.Generics.collections,
  system.Classes,  system.SysUtils,
  sdl2,
  px.sdl;

type

PUIStyle = ^TUIStyle;
TUIStyle = record
  bk :TSDL_Color;
  fg :TSDL_Color;
  hoverBk :TSDL_color;
  hoverFg :TSDL_color;
  activeBk :TSDL_color;
  activeFg :TSDL_color;
  disabledBk :TSDL_color;
  disabledFg :TSDL_color;
end;

TAreaState = ( asNormal, asHover, asActive, asDisabled);

{ TArea is like our TControl  }
//CArea = class of TArea;
TArea = class
  public
    class function Align(const client:TArea; itemW, itemH :integer; alignX :single ; alignY :single  ):TSDL_point;overload; //align to middle with 0.5
    class procedure Align(const client:TArea; child:TArea; alignX, alignY:single);overload;
  public
    type
      TListAreas = TList<TArea>;
      TUIEventMouseButton = reference to procedure(sender:TArea; const mEvent:TSDL_MouseButtonEvent );
      TUIEventMouseMove = reference to procedure(sender:TArea;const mEvent:TSDL_MouseMotionEvent );
      TUIEvent = reference to procedure( sender :TArea );
  private
    fState :TAreaState;
    fPrivateTag :integer;
    fText: string;
    procedure SetPos(const Value: TSDL_Point);
    procedure setText(const Value: string);
  protected
    fParent :TArea;
    fPapaOwnsMe :boolean;
    fChilds :TListAreas;
    fRect   :TSDL_Rect;   //rects X,Y are in Screen coordinates;
    fLocal  :TSDL_Point;    //Local coordinates;
    fCatchInput :boolean;
    fVisible :boolean;
    fShowStates :boolean;
    fStyle :TUIStyle;
    fCurrBk : TSDL_Color;
    fCurrFg : TSDL_Color;
    fTextPos :TSDL_Point;

    class var fLastMouseMoveArea :TArea;
    class var fLastMouseDownArea :TArea;

    procedure updateScreenCoords;
    procedure setRect(x, y, h, w: integer);
    procedure setState( newState :TAreaState );
    procedure doMouseDown(const mEvent : TSDL_MouseButtonEvent );virtual;
    procedure doMouseUp(const mEvent : TSDL_MouseButtonEvent );virtual;
    procedure doClick(mEvent :TSDL_MouseButtonEvent);virtual; //this one is trigered only if the mouseUp was in the same TArea than mouseDown;
    procedure doMouseMove(const mEvent : TSDL_MouseMotionEvent );virtual;
    procedure doMouseEnter;
    procedure doMouseLeave;
    function alignedTextPos:TSDL_Point;
  public
    OnMouseMove :TUIEventMouseMove;
    OnMouseDown :TUIEventMouseButton;
    OnMouseUp   :TUIEventMouseButton;
    OnMouseClick  :TUIEventMouseButton;
    papaOwnsMe :boolean;
    Visible :boolean;
    TextAlignX, TextAlignY :single; //from 0 - 1, 0 is left, 0.5 middle and 1 is right.
    contentPadding :integer;
    Tag :integer;
    constructor create;
    destructor Destroy;override;
    procedure setXY( x,y :integer );
    procedure setWH( w,h :integer );virtual;
    procedure addChild( newChild : TArea);overload;
    procedure addChild( newChild : TArea; alignX, alignY:single );overload;
    procedure addChildBellow( newChild, bellowWho :TArea; sameWH:boolean = false; alignX :single = 0 ); //both has to be childs
    procedure draw;virtual;

    function Consume_MouseButton(const mEvent : TSDL_MouseButtonEvent ):boolean;
    function Consume_MouseMove(const mEvent :TSDL_MouseMotionEvent ):boolean;

    property Text :string read fText write setText;
    property pos : TSDL_Point read fLocal write SetPos;
    property width:integer read fRect.w;
    property height:integer read fRect.h;
    property childs:TListAreas read fChilds;
 end;

TGuisoButton = class(TArea);

TGuisoPanel = class (TArea)
  public
    constructor create;
end;

TGuisoLabel = class(TArea)
public
    constructor create;
    procedure draw;override;
end;

TGuisoCheckBox = class(TArea)
  private
    procedure setChecked(const Value: boolean);
protected
  fChecked :boolean;
  procedure doClick(mEvent :TSDL_MouseButtonEvent);override;
public
  checkRectPadd :integer;
  constructor create;
  procedure setWH( w,h :integer );override;
  procedure draw; override;
  property Checked :boolean read fChecked write setChecked;
end;

//radio group
//only OnClick event will work from the user side, other are ignored;
TGuisoRadioGroup = class(TArea)
  private
    procedure setItemIndex(const Value: integer);
  protected
    fItems :TStrings;
    fSelected :integer;
    fSelectedText :string;
    fSelectedItem :TGuisoCheckBox;
    procedure onChildsClick( sender:TArea; const mMouse :TSDL_MouseButtonEvent);
  public
    OnChange :TArea.TUIEvent;
    constructor create( items:TStrings; itemsW, itemsH :integer );
    destructor Destroy; override;
    property Selected:integer read fSelected write setItemIndex;
    property SelectedText :string read fSelectedText;
end;

TGuisoSlider = class(TArea)
  private
    fOnChangeCall :boolean;
    procedure setValue(const Value: single);
  protected
    fValue :single;
    fMin, fMax :single;
    fSliderBar, fSlider :TSDL_Rect;
    procedure doMouseMove(const mEvent : TSDL_MouseMotionEvent );override;
    procedure UpdateRects;
  public
    sliderRectPadd :integer;
    OnChange :TArea.TUIEvent;
    constructor create;
    procedure draw;override;
    procedure setMinMax( aMin, aMax :single);
    property Value:single read fValue write setValue;
end;

TGuisoScreen = class( TArea )
  private
  public
    constructor create;
    destructor Destroy;override;
    procedure draw;override;
 end;

 var
  styleDefault, stylePanel :TUIStyle;

{------------------------------------------------------------------------------}
implementation



{ TArea }


procedure TArea.addChild(newChild: TArea);
begin
  if (newChild<>self) and (newChild<>nil) then
  begin
    fChilds.Add(newChild);
    newChild.fPapaOwnsMe := true;
    newChild.fParent := self;
  end else sdl.errorMsg('GUI: You cannot add itself or nil as TArea child');
end;

class function TArea.Align(const client: TArea; itemW, itemH: integer; alignX,
  alignY: single): TSDL_point;
var
  x,y, w, h :integer;
  tz :TSDL_Point;
begin
  x := client.fRect.x + client.contentPadding;
  w := client.fRect.w - client.contentPadding;
  w := w - client.contentPadding;
  y := client.fRect.y + client.contentPadding;
  h := client.fRect.h - client.contentPadding;
  h := h - client.contentPadding;
  Result.x := x + round( w * alignX - itemW * alignX );
  Result.y := y + round( h * alignY - itemH * alignY );
end;

function TArea.AlignedTextPos: TSDL_Point;
var
  ts :TSDL_point;
begin
  ts := sdl.textSize(Text);
  Result := TArea.Align(self, ts.x, ts.y, TextAlignX, TextAlignY );
end;


function TArea.Consume_MouseButton(const mEvent: TSDL_MouseButtonEvent): boolean;
var
  i :integer;
  pos :TSDL_Point;
begin
  Result := false;
  if ( not fVisible ) or ( mEvent.button <> 1 ) then exit;
  //for all of these three mouse events, XY are in the same position of the record union
  pos.x := mEvent.x;
  pos.y := mEvent.y;
  if SDL_PointInRect(@pos, @fRect ) then
  begin
    //is inside ok, but let's see if my childs consume this input:
    //mouse inputs are processed in the reverse order of how the GUI areas are painted.
    for i := fChilds.Count-1 downto 0 do
    begin
      Result := fChilds.List[i].Consume_MouseButton(mEvent);
      if Result then break;
    end;
    //if non of my childs consumed the input then I eat it.
    if (not Result) and (fCatchInput) then
    begin
      Result := true;
      if mEvent.type_ = SDL_MOUSEBUTTONDOWN then doMouseDown(mEvent) else doMouseUp(mEvent);
    end;
  end
end;

function TArea.Consume_MouseMove(const mEvent: TSDL_MouseMotionEvent): boolean;
var
  i :integer;
  pos :TSDL_Point;
begin
  Result := false;
  if ( not fVisible ) then exit;
  //for all of these three mouse events, XY are in the same position of the record union
  pos.x := mEvent.x;
  pos.y := mEvent.y;
  if SDL_PointInRect(@pos, @fRect ) then
  begin
    //is inside ok, but let's see if my childs consume this input:
    //mouse inputs are processed in the reverse order of how the GUI areas are painted.
    for i := fChilds.Count-1 downto 0 do
    begin
      Result := fChilds.List[i].Consume_MouseMove(mEvent);
      if Result then break;
    end;
    //if non of my childs consumed the input then I eat it.
    if (not Result) and (fCatchInput) then
    begin
      Result := true;
      if fCatchInput then doMouseMove(mEvent);
      if fLastMouseMoveArea<>self then
      begin
        if assigned(fLastMouseMoveArea)  then if fLastMouseMoveArea.fCatchInput then fLastMouseMoveArea.doMouseLeave;
        fLastMouseMoveArea := self;
        if fCatchInput then doMouseEnter;
      end;
    end;
  end;
end;

constructor TArea.create;
begin
  fParent := nil;
  fChilds := TListAreas.create;
  fRect := sdl.Rect(0,0, 100, 20);
  fCatchInput := true;
  fPapaOwnsMe := true;
  fVisible := true;
  fShowStates := true;
  fStyle := styleDefault;
  setState( asNormal );
  fLastMouseMoveArea := nil;
  TextAlignX := 0.5;
  TextAlignY := 0.5;
  contentPadding := 2;
end;

destructor TArea.Destroy;
var
  i :integer;
begin
  //kill childs first
  for i := 0 to fChilds.Count-1 do
    if fChilds.List[i].fPapaOwnsMe then fChilds.List[i].Free;
  fChilds.Free;
end;


procedure TArea.doMouseMove(const mEvent: TSDL_MouseMotionEvent);
begin
  if assigned(OnMouseMove) then OnMouseMove(self, mEvent);
end;

procedure TArea.doClick(mEvent: TSDL_MouseButtonEvent);
begin
  if assigned(OnMouseClick) then OnMouseClick(Self, mEvent);
end;

procedure TArea.doMouseDown(const mEvent: TSDL_MouseButtonEvent);
begin
  setState( asActive );
  fLastMouseDownArea := self;
  if assigned(OnMouseDown) then OnMouseDown(self, mEvent);
end;

procedure TArea.doMouseEnter;
begin
//  sdl.print('Entering :'+Text);
  setState(asHover);
end;

procedure TArea.doMouseLeave;
begin
//  sdl.print('Leaving :'+Text);
  setState(asNormal);
end;

procedure TArea.doMouseUp(const mEvent: TSDL_MouseButtonEvent);
begin
  if assigned(OnMouseUp) then OnMouseUp(self, mEvent);
  setState( asHover );
  if fLastMouseDownArea = self then doClick(mEvent);
end;

procedure TArea.draw;
var
  i :integer;
  textPos :TSDL_point;
begin
  if fVisible  then
  begin
    sdl.setColor( fCurrBk );
    SDL_RenderFillRect(sdl.rend, @fRect);
    if Text<>'' then
    begin
      textPos := alignedTextPos;
      sdl.drawText(Text, TextPos.x, TextPos.y, cardinal(fCurrFg));
    end;
    //TODO: mabe clip the area of the childs here?
    for i := 0 to fChilds.Count - 1 do fChilds.List[i].draw;
  end;
end;

procedure TArea.addChild( newChild : TArea; alignX, alignY:single );
var
  newPos :TSDL_Point;
begin
  if (newChild<>self) and (newChild<>nil) then
  begin
    fChilds.Add(newChild);
    newChild.fPapaOwnsMe := true;
    newChild.fParent := self;
    TArea.Align(self, newChild, alignX, alignY);
  end else sdl.errorMsg('GUI: You cannot add itself or nil as TArea child');
end;

procedure TArea.addChildBellow(newChild, bellowWho: TArea; sameWH:boolean; alignX: single);
var
  newPos :TSDL_Point;
begin
  if (newChild<>self) and (newChild<>nil) then
  begin
    fChilds.Add(newChild);
    newChild.fPapaOwnsMe := true;
    newChild.fParent := self;
    if sameWH then newChild.setWH(bellowWho.width, bellowWho.height);
    newPos.y := bellowWho.pos.y + bellowWho.height + contentPadding;
    newPos.x := bellowWho.pos.x + round(bellowWho.width * alignX - newChild.width * alignX);
    newChild.pos := newPos;
  end else sdl.errorMsg('GUI: You cannot add itself or nil as TArea child');
end;

class procedure TArea.Align(const client: TArea; child: TArea; alignX, alignY:single);
var
  x,y, w, h :integer;
begin
  x := client.contentPadding;
  w := client.fRect.w - client.contentPadding;
  w := w - client.contentPadding;
  y := client.contentPadding;
  h := client.fRect.h - client.contentPadding;
  h := h - client.contentPadding;
  x := x + round( w * alignX - child.width * alignX );
  y := y + round( h * alignY - child.height * alignY );
  child.setXY(x,y);
end;

procedure TArea.SetPos(const Value: TSDL_Point);
begin
  SetXY(Value.x, Value.y);
end;

procedure TArea.setRect(x, y, h, w : integer );
begin
  fRect := sdl.Rect(x,y,h,w);
  updateScreenCoords;
end;

procedure TArea.setState(newState: TAreaState);
begin
  fState := newState;
  if fShowStates then
    case newState of
      asNormal: begin fCurrfg := fStyle.fg ; fCurrBk := fStyle.bk end;
      asHover: begin fCurrfg := fStyle.hoverFg ; fCurrBk := fStyle.hoverBk end;
      asActive: begin fCurrfg := fStyle.activeFg ; fCurrBk := fStyle.activeBk end;
      asDisabled: begin fCurrfg := fStyle.disabledFg ; fCurrBk := fStyle.disabledBk end;
    end;
end;

procedure TArea.setText(const Value: string);
begin
  fText := Value;
end;

procedure TArea.setWH(w, h: integer);
begin
  fRect.w := w;
  fRect.h := h;
end;

procedure TArea.setXY(x, y: integer);
begin
  fLocal.x := x;
  fLocal.y := y;
  updateScreenCoords;
end;

{
  since UI most time are static, is better to update the screen coords of the childs
  any time its local x,y are changed than recalculate it every time this coords
  are needed to draw on the screen.
}
procedure TArea.updateScreenCoords;
var
  i: Integer;
begin
  if assigned(fParent) then
  begin
    fRect.x := fParent.fRect.x + fLocal.x;
    fRect.y := fParent.fRect.y + fLocal.y;
  end else
  begin
    fRect.x := fLocal.x;
    fRect.y := fLocal.y;
  end;
  for i := 0 to fChilds.Count-1 do fChilds[i].updateScreenCoords;
end;


{ TGuisoScreen }

constructor TGuisoScreen.create;
begin
  inherited;
  setRect(0,0, sdl.LogicalSize.x, sdl.logicalsize.y);
  fCatchInput := false;
end;

destructor TGuisoScreen.Destroy;
begin

  inherited;
end;

procedure TGuisoScreen.draw;
var
  i: Integer;
begin
  if fVisible then
    for i := 0 to fChilds.Count-1 do fChilds.List[i].draw;
end;

{ TGuisoPanel }

constructor TGuisoPanel.create;
begin
  inherited;
  fStyle := stylePanel;
  setState(asNormal);
  fShowStates := false;
end;

{ TGuisoCheckBox }


{ TGuisoCheckBox }

constructor TGuisoCheckBox.create;
begin
  inherited;
  TextAlignX := 0.1;
  checkRectPadd := 5;
end;

procedure TGuisoCheckBox.doClick(mEvent: TSDL_MouseButtonEvent);
begin
  setChecked( not fChecked );
  inherited;
end;

procedure TGuisoCheckBox.draw;
var
  checkRect :TSDL_Rect;
begin
//  if fChecked then fCurrFg := fStyle.activeFg;
  if fVisible then
  begin
    inherited draw;
    checkRect.x := fRect.x + checkRectPadd;
    checkRect.y := fRect.y + checkRectPadd;
    checkRect.h := fRect.h - checkRectPadd * 2;
    checkRect.w := checkRect.h;
    if fChecked then
    begin
      sdl.setColor( fStyle.activeBk );
      SDL_RenderFillRect(sdl.rend, @checkRect);
    end else
    begin
      sdl.setColor( fStyle.disabledBk );
      SDL_RenderFillRect(sdl.rend, @checkRect);
    end;
  end;
end;

procedure TGuisoCheckBox.setChecked(const Value: boolean);
begin
  fChecked := Value;
  //if fChecked then TextAlignX := 0.9 else TextAlignX := 0.1;
end;

procedure TGuisoCheckBox.setWH(w, h: integer);
begin
  inherited;
  contentPadding := h;
end;

{ TGuisoLabel }

constructor TGuisoLabel.create;
begin
  inherited;
  fShowStates := false;
  fCatchInput := false;
  setWH(1,1);
//  TextAlignX := 0;
//  TextAlignY := 0;
end;

procedure TGuisoLabel.draw;
var
  i :integer;
  tpos :TSDL_Point;
begin
  if fVisible  then
  begin
    if Text <>'' then
    begin
      tpos := alignedTextPos;
      sdl.drawText(Text, tpos.x, tpos.y, cardinal(fCurrFg));
    end;
    for i := 0 to fChilds.Count - 1 do fChilds.List[i].draw;
  end;
end;

{ TGuisoRadioGroup }
{ TGruisoRadioGroup will own the TStrings now, and will free it when destroy is called
do not modify string list, not yet }
constructor TGuisoRadioGroup.create;
var
  newChild :TGuisoCheckBox;
  i: Integer;
begin
  inherited create;
  fCatchInput := false;
  fShowStates := false;

  fItems := items;
  setWH( itemsW, itemsH * fItems.Count);
  for i := 0 to fItems.Count-1 do
  begin
    newChild := TGuisoCheckBox.create;
    newChild.setWH(itemsW, itemsH);
    addChild(newChild);
    newChild.setXY(0, i * itemsH);
    fItems.Objects[i] := newChild;
    newChild.Text := fItems.Strings[i];
    newChild.OnMouseClick := onChildsClick;
    newChild.fPrivateTag := i;
  end;
  fSelected := -1;
  fSelectedText := '';
  fSelectedItem := nil;
end;

destructor TGuisoRadioGroup.Destroy;
begin
  if assigned(fItems) then fItems.Free;
  inherited;
end;

procedure TGuisoRadioGroup.onChildsClick(sender: TArea;
  const mMouse: TSDL_MouseButtonEvent);
begin
  if fSelected = sender.fPrivateTag then
  begin
    (sender as TGuisoCheckBox).Checked := true;
    self.doClick(mMouse);
    exit;
  end;
  if fSelected<>-1 then fSelectedItem.Checked := false;
  fSelected := sender.fPrivateTag;
  fSelectedItem := sender as TGuisoCheckBox;
  fSelectedText := sender.Text;
  self.doClick(mMouse);
  if Assigned(OnChange) then OnChange(self);
end;

procedure TGuisoRadioGroup.setItemIndex(const Value: integer);
begin
  if (Value>=0) and (Value<fItems.Count) then
  begin
    if fSelected<>-1 then fSelectedItem.Checked := false;
    fSelected := Value;
    fSelectedText := fItems[Value];
    fSelectedItem := fItems.Objects[Value] as TGuisoCheckBox;
    fSelectedItem.Checked := true;
  end;
end;

{ TGuisoSlider }

constructor TGuisoSlider.create;
begin
  inherited create;
  setMinMax(0,100);
  setValue(0);
  TextAlignX := 1;
  sliderRectPadd := 5;
  contentPadding := 2;
  UpdateRects;
  fOnChangeCall := false;
end;

procedure TGuisoSlider.doMouseMove(const mEvent: TSDL_MouseMotionEvent);
var
  dv : single;
begin
  if (mEvent.state and SDL_BUTTON_LMASK)>0 then
  begin
    dv :=  (mEvent.xrel * (fMax - fMin)) / (fRect.w - fRect.h div 2);
    Value := Value + dv;
    setState(asActive);
    UpdateRects;
    fOnChangeCall := true;
    if assigned(OnChange) then OnChange(self);
    fOnChangeCall := false;
  end;
  inherited;
end;

procedure TGuisoSlider.draw;
var
  i :integer;
begin
  if fVisible then
  begin
    inherited draw;
    UpdateRects;
    sdl.setColor(fStyle.disabledBk);
    SDL_RenderFillRect(sdl.rend, @fSliderBar);
    if fState = asActive then sdl.setColor(fStyle.activeFg) else sdl.setColor(fStyle.fg);
    SDL_RenderFillRect(sdl.rend, @fSlider);
  end;
end;

procedure TGuisoSlider.setMinMax(aMin, aMax: single);
begin
  fMin := aMin;
  fMax := aMax;
  UpdateRects;
end;

procedure TGuisoSlider.setValue(const Value: single);
begin
  fValue := Value;
  if Value<fMin then fValue := fMin;
  if Value>fMax then fValue := fMax;
  //avoid infinite loop, in case someone change Value from OnChange;
  if not fOnChangeCall then if assigned(onChange) then OnChange( self );
end;

procedure TGuisoSlider.UpdateRects;
var
  sliderWH :integer;
  valuePos :integer;
begin
    fSliderBar.x := fRect.x + contentPadding;
    fSliderBar.y := fRect.y + (fRect.h div 2) - contentPadding;
    fSliderBar.w := fRect.w - 2 * contentPadding;
    fSliderBar.h := 2* contentPadding;
    sdl.setColor(fStyle.disabledBk);
    SDL_RenderFillRect(sdl.rend, @fSliderBar);

    sliderWH := fRect.h - sliderRectPadd*2;
    valuePos := contentPadding + (sliderWH div 2) + round( (fValue * (fSliderBar.w - sliderWH - contentPadding))/(fMax - fMin));
    fSlider.x := fRect.x + valuePos - sliderWH div 2;
    fSlider.y := fRect.y + sliderRectPadd;
    fSlider.w := sliderWH;
    fSlider.h := sliderWH;
end;


initialization
  with styleDefault do
  begin
    fg := sdl.color(180,180,180);
    bk := sdl.color(50, 50, 50);
    hoverFg := sdl.color(250, 250, 250);
    hoverBk := sdl.color(30, 100, 20);
    activeFg := sdl.color(255, 255, 255);
    activeBk := sdl.color(220, 120, 5);
    disabledFg := sdl.color(100, 100, 100);
    disabledBk := sdl.color(30, 30, 30);
  end;
  stylePanel := styleDefault;
  with stylePanel do
  begin
    Fg := sdl.color(150, 150, 150);
    Bk := sdl.color(20, 20, 20);
  end;
finalization
end.
