object SynthResModule: TSynthResModule
  OldCreateOrder = False
  Left = 277
  Top = 202
  Height = 480
  Width = 696
  object ControlMenu: TPopupMenu
    OnPopup = ControlMenuPopup
    Left = 30
    Top = 25
    object mnuControlReset: TMenuItem
      Caption = 'Reset'
      OnClick = mnuControlResetClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
  end
end
