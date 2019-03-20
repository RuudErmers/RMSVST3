object SynthEditorForm: TSynthEditorForm
  Left = 359
  Top = 165
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsNone
  Caption = 'SynthEditorForm'
  ClientHeight = 55
  ClientWidth = 219
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object VolumeBar: TTrackBar
    Left = 5
    Top = 10
    Width = 211
    Height = 36
    Hint = '|Volume'
    Max = 127
    Orientation = trHorizontal
    Frequency = 4
    Position = 64
    SelEnd = 0
    SelStart = 0
    TabOrder = 0
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = VolumeBarChange
  end
end
