import gettext
import builtins
from PyQt5.QtCore import QSettings
import appTranslation as fcTranslate
from appGUI.GUIElements import *


fcTranslate.apply_language('strings')
if '_' not in builtins.__dict__:
	_ = gettext.gettext

settings = QSettings("Open Source", "FlatCAM")
if settings.contains("machinist"):
	machinist_setting = settings.value('machinist', type=int)
else:
	machinist_setting = 0
