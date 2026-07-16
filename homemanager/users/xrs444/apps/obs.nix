{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = [ pkgs.obs-cmd ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture
      advanced-scene-switcher
      obs-vkcapture
      obs-backgroundremoval
      obs-composite-blur
      obs-gstreamer
      obs-retro-effects
      obs-vaapi
      obs-transition-table
      waveform
    ];
  };

  # Theme files are read-only; OBS never writes to them — inline content
  # (no external file tree; matches the rest of the repo's xdg.configFile.text pattern).
  xdg.configFile = {
    "obs-studio/themes/Catppuccin.obt".text = ''
@OBSThemeMeta {
    name: 'Catppuccin';
    id: 'com.obsproject.Catppuccin';
    author: 'Xurdejl';
    dark: 'true';
}

@OBSThemeVars {
    --palette_window: var(--ctp_mantle);
    --palette_windowText: var(--ctp_subtext0);

    --palette_base: var(--ctp_mantle);
    --palette_alternateBase: var(--ctp_crust);

    --palette_text: var(--ctp_text);

    --palette_button: var(--ctp_surface0);
    --palette_buttonText: var(--ctp_subtext0);

    --palette_brightText: var(--ctp_subtext0);

    --palette_light: var(--ctp_surface0);
    --palette_mid: var(--ctp_base);
    --palette_dark: var(--ctp_mantle);
    --palette_shadow: var(--ctp_crust);

    --palette_primary: var(--ctp_surface1);
    --palette_primaryLight: var(--ctp_blue);
    --palette_primaryDark: var(--ctp_crust);

    --palette_highlight: var(--ctp_blue);
    --palette_highlightText: var(--ctp_subtext0);

    --palette_text: var(--ctp_text);
    --palette_link: var(--ctp_rosewater);
    --palette_linkVisited: var(--ctp_flamingo);

    --palette_windowText_disabled: var(--ctp_overlay1);
    --palette_text_disabled: var(--ctp_overlay1);
    --palette_button_disabled: var(--ctp_base);

    --palette_buttonText_disabled: var(--ctp_mantle);
    --palette_brightText_disabled: var(--ctp_mantle);

    --palette_text_inactive: var(--ctp_subtext0);

    --palette_highlight_inactive: var(--ctp_crust);
    --palette_highlightText_inactive: var(--ctp_text);

    /* Layout */
    /* Configurable Values */
    --font_base_value: 10;   /* TODO: Min 8, Max 12, Step 1 */
    --spacing_base_value: 4; /* TODO: Min 2, Max 7, Step 1 */
    --padding_base_value: 4; /* TODO: Min 0.25, Max 10, Step 2 */

    --border_highlight: "transparent"; /* TODO: Better Accessibility focus state */
    /* TODO: Move Accessibilty Colors to Theme config system */

    /* OS Fixes */
    --os_mac_font_base_value: 12;

    --font_base: calc(1pt * var(--font_base_value));
    --font_small: calc(0.9pt * var(--font_base_value));
    --font_large: calc(1.1pt * var(--font_base_value));
    --font_xlarge: calc(1.5pt * var(--font_base_value));

    --font_heading: calc(2.5pt * var(--font_base_value));

    --icon_base: calc(6px + var(--font_base_value));

    --spacing_base: calc(0.5px * var(--spacing_base_value));
    --spacing_large: calc(1px * var(--spacing_base_value));
    --spacing_small: calc(0.25px * var(--spacing_base_value));
    --spacing_title: 4px;

    --padding_base: calc(0.5px * var(--padding_base_value));
    --padding_large: calc(1px * var(--padding_base_value));
    --padding_xlarge: calc(1.75px * var(--padding_base_value));
    --padding_small: calc(0.25px * var(--padding_base_value));

    --padding_wide: calc(8px + calc(2 * var(--padding_base_value)));
    --padding_menu: calc(4px + calc(2 * var(--padding_base_value)));

    --padding_base_border: calc(var(--padding_base) + 1px);

    --spinbox_button_height: calc(var(--input_height_half) - 1px);

    --volume_slider: calc(calc(4px + var(--font_base_value)) / 4);
    --volume_slider_box: calc(var(--volume_slider) * 4);
    --volume_slider_label: calc(var(--volume_slider_box) * 2);

    --scrollbar_size: 12px;
    --settings_scrollbar_size: calc(var(--scrollbar_size) + 9px);

    /* Inputs / Controls */
    --border_radius: 4px;
    --border_radius_small: 2px;
    --border_radius_large: 6px;

    --input_font_scale: calc(var(--font_base_value) * 2.2);
    --input_font_padding: calc(var(--padding_base_value) * 2);

    --input_height_base: calc(var(--input_font_scale) + var(--input_font_padding));
    --input_padding: var(--padding_large);
    --input_height: calc(var(--input_height_base) - calc(var(--input_padding) * 2));
    --input_height_half: calc(var(--input_height_base) / 2);

    --spacing_input: var(--spacing_base);
}

/* --------------------- */
/* General Styling Hints */

/* Backgrounds */

.bg_window {
    background-color: var(--ctp_base);
}

.bg-base {
    background-color: palette(base);
}

.text-heading {
    font-size: var(--font_heading);
    font-weight: bold;
}

.text-large {
    font-size: var(--font_large);
}

.text-bright {
    color: var(--ctp_surface0);
}

.text-muted {
    color: var(--ctp_overlay1);
}

.text-warning {
    color: var(--ctp_peach);
}

.text-danger {
    color: var(--ctp_maroon);
}

.text-success {
    color: var(--ctp_green);
}

.frame-notice {
    background: var(--ctp_crust);
    border-radius: var(--border_radius);
    padding: var(--padding_xlarge) var(--padding_large);
}

.frame-notice QLabel {
    padding: var(--padding_large) 0px;
}

/* Icon Overrides */

.icon-plus {
    qproperty-icon: url(theme:Dark/plus.svg);
}

.icon-minus {
    qproperty-icon: url(theme:Dark/minus.svg);
}

.icon-trash {
    qproperty-icon: url(theme:Dark/trash.svg);
}

.icon-clear {
    qproperty-icon: url(theme:Dark/entry-clear.svg);
}

.icon-gear {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

.icon-dots-vert {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

.icon-refresh {
    qproperty-icon: url(theme:Dark/refresh.svg);
}

.icon-cogs {
    qproperty-icon: url(theme:Dark/cogs.svg);
}

.icon-touch {
    qproperty-icon: url(theme:Dark/interact.svg);
}

.icon-up {
    qproperty-icon: url(theme:Dark/up.svg);
}

.icon-down {
    qproperty-icon: url(theme:Dark/down.svg);
}

.icon-pause {
    qproperty-icon: url(theme:Dark/media-pause.svg);
}

.icon-filter {
    qproperty-icon: url(theme:Dark/filter.svg);
}

.icon-revert {
    qproperty-icon: url(theme:Dark/revert.svg);
}

.icon-save {
    qproperty-icon: url(theme:Dark/save.svg);
}

/* Media icons */

.icon-media-play {
    qproperty-icon: url(theme:Dark/media/media_play.svg);
}

.icon-media-pause {
    qproperty-icon: url(theme:Dark/media/media_pause.svg);
}

.icon-media-restart {
    qproperty-icon: url(theme:Dark/media/media_restart.svg);
}

.icon-media-stop {
    qproperty-icon: url(theme:Dark/media/media_stop.svg);
}

.icon-media-next {
    qproperty-icon: url(theme:Dark/media/media_next.svg);
}

.icon-media-prev {
    qproperty-icon: url(theme:Dark/media/media_previous.svg);
}

/* Default widget style, we override only what is needed. */

QWidget {
    alternate-background-color: palette(base);
    color: palette(text);
    selection-background-color: var(--ctp_selection_background);
    selection-color: palette(text);
    font-size: var(--font_base);
    font-family: 'Open Sans', '.AppleSystemUIFont', Helvetica, Arial, 'MS Shell Dlg', sans-serif;
}

QWidget:disabled {
    color: var(--ctp_overlay1);
}

/* Container windows */

QDialog,
QMainWindow,
QStatusBar,
QMenuBar,
QMenu {
    background-color: var(--ctp_base);
}

/* macOS Separator Fix */

QMainWindow::separator {
    background: transparent;
    width: var(--spacing_large);
    height: var(--spacing_large);
    margin: 0px;
}

QMainWindow::separator:hover {
    border: 1px solid transparent;
    margin: 1px;
}

/* General Widgets */

QLabel,
QGroupBox,
QCheckBox {
    background: transparent;
}

QComboBox,
QCheckBox,
QPushButton,
QSpinBox,
QDoubleSpinBox {
    margin-top: var(--spacing_input);
    margin-bottom: var(--spacing_input);
}

QListWidget QWidget,
SceneTree QWidget,
SourceTree QWidget {
    margin-top: 0;
    margin-bottom: 0;
}

* [frameShape="1"],
* [frameShape="2"],
* [frameShape="3"],
* [frameShape="4"],
* [frameShape="5"],
* [frameShape="6"] {
    border: 1px solid palette(dark);
}


/* Misc */

QAbstractItemView {
    background-color: palette(base);
}

QToolTip {
    background-color: palette(base);
    color: palette(text);
    border: none;
}

/* Context Menu */

QMenu::icon {
    left: 4px;
}

QMenu::separator {
    background: var(--ctp_overlay0);
    height: 1px;
    margin: var(--spacing_base) var(--spacing_large);
}

QMenu::item:disabled {
    color: var(--ctp_overlay1);
    background: transparent;
}

QMenu::right-arrow {
    image: url(theme:Dark/expand.svg);
}

/* Top Menu Bar Items */
QMenuBar::item {
    background-color: transparent;
}

QMenuBar::item:selected {
    background: var(--ctp_surface1);
}

/* Item Lists */
QListWidget {
    border-radius: var(--border_radius);
}

QListWidget::item {
    color: palette(text);
}

QListWidget,
QMenu,
SceneTree,
SourceTree {
    padding: var(--spacing_base);
}

QListWidget::item,
SourceTreeItem,
SceneTree::item {
    padding: var(--padding_large);
}

QMenu::item {
    padding: var(--padding_large) var(--padding_menu);
    padding-right: 20px;
}

QListWidget::item,
SourceTreeItem,
QMenu::item,
SceneTree::item {
    border-radius: var(--border_radius);
    color: palette(text);
    border: 1px solid transparent;
}

SourceTree::item {
    border-radius: var(--border_radius);
    color: palette(text);
}

QMenu::item:selected,
QListWidget::item:selected,
SceneTree::item:selected,
SourceTree::item:selected {
    background-color: var(--ctp_surface1);
}

QMenu::item:hover,
QListWidget::item:hover,
SceneTree::item:hover,
SourceTree::item:hover,
QMenu::item:selected:hover,
QListWidget::item:selected:hover,
SceneTree::item:selected:hover,
SourceTree::item:selected:hover {
    background-color: var(--ctp_surface0);
    color: palette(text);
}

QMenu::item:focus,
QListWidget::item:focus,
SceneTree::item:focus,
SourceTree::item:focus,
QMenu::item:selected:focus,
QListWidget::item:selected:focus,
SceneTree::item:selected:focus,
SourceTree::item:selected:focus {
    border: 1px solid var(--border_highlight);
}

QListWidget::item:disabled,
QListWidget::item:disabled:hover,
SourceTree::item:disabled,
SourceTree::item:disabled:hover,
SceneTree::item:disabled,
SceneTree::item:disabled:hover {
    background: transparent;
    color: var(--ctp_overlay1);
}

QListWidget QLineEdit,
SceneTree QLineEdit,
SourceTree QLineEdit {
    padding: 0;
    padding-bottom: 1px;
    margin: 0;
    border: 1px solid var(--ctp_text);
    border-radius: var(--border_radius);
}

QListWidget QLineEdit:focus,
SceneTree QLineEdit:focus,
SourceTree QLineEdit:focus {
    border: 1px solid var(--ctp_text);
}

/* Settings QList */

OBSBasicSettings QListWidget {
    border-radius: var(--border_radius);
    padding: var(--spacing_base);
}

OBSBasicSettings QListWidget::item {
    border-radius: var(--border_radius);
    padding: var(--padding_large);
}

OBSBasicSettings QScrollBar:vertical {
    width: var(--settings_scrollbar_size);
    margin-left: 9px;
}

OBSBasicSettings QScrollBar:horizontal {
    height: var(--settings_scrollbar_size);
    margin-top: 9px;
}

/* Settings properties view */
OBSBasicSettings #PropertiesContainer {
    background-color: palette(dark);
}

/* Dock Widget */
OBSDock > QWidget {
    background: palette(dark);
    border-bottom-left-radius: var(--border_radius);
    border-bottom-right-radius: var(--border_radius);
    border: 1px solid var(--ctp_mantle);
    border-top: none;
}

#transitionsFrame {
    padding: var(--padding_large);
}

OBSDock QLabel {
    background: transparent;
}

QDockWidget {
    font-size: var(--font_base);
    font-weight: bold;

    titlebar-close-icon: url(theme:Dark/close.svg);
    titlebar-normal-icon: url(theme:Dark/popout.svg);
}

QDockWidget::title {
    text-align: left;
    background-color: palette(base);
    padding: var(--padding_large);
    border-top-left-radius: var(--border_radius);
    border-top-right-radius: var(--border_radius);
}

QDockWidget::close-button,
QDockWidget::float-button {
    border: none;
    border-radius: var(--border_radius);
    background: transparent;
    margin-right: 1px;
}

QDockWidget::close-button:hover,
QDockWidget::float-button:hover {
    background: var(--ctp_surface1);
}

QDockWidget::close-button:pressed,
QDockWidget::float-button:pressed {
    padding: 1px -1px -1px 1px;
}

QScrollArea {
    border-radius: var(--border_radius);
}

/* Qt enforces a padding inside its status bar, so we
 * oversize it and use margin to crunch it back down
 */
OBSBasicStatusBar {
    margin-top: 4px;
    border-top: 1px solid var(--ctp_mantle);
    background: palette(dark);
}

StatusBarWidget > QFrame {
    margin-top: 1px;
    border: 0px solid transparent;
    border-left-width: 1px;
    padding: 0px 8px 2px;
}

/* Group Box */

QGroupBox {
    background: palette(dark);
    border-radius: var(--border_radius);
    padding-top: var(--input_height_base);
    padding-bottom: var(--padding_large);
    font-weight: bold;
    margin-bottom: var(--spacing_large);
}

QGroupBox::title {
    subcontrol-origin: margin;
    left: var(--spacing_title);
    top: var(--spacing_title);
}


/* ScrollBars */

QScrollBar {
    background-color: var(--ctp_crust);
    margin: 0px;
    border-radius: var(--border_radius);
}

::corner {
    background-color: palette(window);
    border: none;
}

QScrollBar:vertical {
    width: var(--scrollbar_size);
}

QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical {
    border: none;
    background: none;
    height: 0px;
}

QScrollBar::up-arrow:vertical,
QScrollBar::down-arrow:vertical,
QScrollBar::add-page:vertical,
QScrollBar::sub-page:vertical {
    border: none;
    background: none;
    color: none;
}

QScrollBar:horizontal {
    height: var(--scrollbar_size);
}

QScrollBar::add-line:horizontal,
QScrollBar::sub-line:horizontal {
    border: none;
    background: none;
    width: 0px;
}

QScrollBar::left-arrow:horizontal,
QScrollBar::right-arrow:horizontal,
QScrollBar::add-page:horizontal,
QScrollBar::sub-page:horizontal {
    border: none;
    background: none;
    color: none;
}

QScrollBar::handle {
    background-color: var(--ctp_surface0);
    margin: 2px;
    border-radius: var(--border_radius_small);
    border: 1px solid var(--ctp_surface0);
}

QScrollBar::handle:hover {
    background-color: var(--ctp_surface1);
    border-color: var(--ctp_surface1);
}

QScrollBar::handle:pressed {
    background-color: var(--ctp_surface0);
    border-color: var(--ctp_surface0);
}

QScrollBar::handle:vertical {
    min-height: 32px;
}

QScrollBar::handle:horizontal {
    min-width: 32px;
}

QScrollBar::handle:disabled {
    background: transparent;
    border-color: transparent;
}

/* Source Context Bar */

#contextContainer {
    background-color: palette(dark);
    margin-top: 4px;
    border-radius: var(--border_radius);
}

#contextContainer QPushButton {
    padding-left: 12px;
    padding-right: 12px;
}

QPushButton#sourcePropertiesButton {
    qproperty-icon: url(theme:Dark/settings/general.svg);
    icon-size: var(--icon_base);
}

QPushButton#sourceFiltersButton {
    qproperty-icon: url(theme:Dark/filter.svg);
    icon-size: var(--icon_base);
}

/* Scenes and Sources toolbar */

QToolBar {
    background-color: transparent;
    border: none;
    margin: var(--spacing_base) 0px;
}

QToolBar QToolBarSeparator {
    background-color: var(--ctp_surface0);
}

QToolBarExtension {
    background: palette(button);
    min-width: 12px;
    max-width: 12px;
    padding: 4px 0px;
    margin-left: 0px;

    qproperty-icon: url(theme:Dark/dots-vert.svg);
}


/* Tab Widget */

/* The tab widget frame */
QTabWidget::pane {
    border-top: 4px solid palette(base);
}

QTabWidget::tab-bar {
    alignment: left;
}

QTabBar QToolButton {
    background: var(--ctp_surface0);
    border: none;
}

QTabBar::tab:top {
    border-top-left-radius: 4px;
    border-top-right-radius: 4px;
}

QTabBar::tab:bottom {
    border-bottom-left-radius: 4px;
    border-bottom-right-radius: 4px;
}

QTabBar::tab {
    background: palette(dark);
    color: palette(text);
    border: none;
    padding: 8px 12px;
    min-width: 50px;
    margin: 1px 0px;
    margin-right: 2px;
    border: 1px solid var(--ctp_overlay0);
}

QTabBar::tab:pressed {
    background: var(--ctp_crust);
}

QTabBar::tab:hover {
    background: var(--ctp_surface1);
    border-color: var(--ctp_overlay0);
    color: palette(text);
}

QTabBar::tab:focus {
    border-color: var(--ctp_overlay0);
}

QTabBar::tab:selected {
    background: var(--ctp_surface0);
    color: palette(text);
}

QTabBar::tab:top {
    border-bottom: 0px solid transparent;
    margin-bottom: 0px;
}

QTabBar::tab:bottom {
    border-top: 0px solid transparent;
    margin-top: 0px;
}

QTabBar QToolButton {
    background: palette(base);
    min-width: 16px;
    padding: 0px;
}

/* ComboBox */

QComboBox,
QDateTimeEdit {
    background-color: var(--ctp_surface0);
    border: 1px solid var(--ctp_surface0);
    border-radius: var(--border_radius);
    padding: var(--padding_large) var(--padding_large);
    padding-left: 10px;
}

QComboBox QAbstractItemView::item:selected,
QComboBox QAbstractItemView::item:hover {
    background-color: var(--ctp_crust);
}

QComboBox:hover,
QComboBox:focus,
QDateTimeEdit:hover,
QDateTimeEdit:selected {
    border-color: var(--ctp_overlay0);
}

QComboBox::drop-down,
QDateTimeEdit::drop-down {
    border: none;
    border-left: 1px solid var(--ctp_crust);
    width: var(--input_height);
}

QComboBox::down-arrow,
QDateTimeEdit::down-arrow {
    qproperty-alignment: AlignTop;
    image: url(theme:Dark/collapse.svg);
    width: 100%;
}

QComboBox:editable:hover {
    background-color: var(--ctp_surface1);
    border-color: var(--ctp_overlay0);
}

QComboBox:on,
QDateTimeEdit:on,
QComboBox:editable:focus {
    background-color: var(--ctp_surface1);
    border-color: var(--ctp_overlay0);
}

QComboBox::drop-down:editable,
QDateTimeEdit::drop-down:editable {
    border-top-right-radius: 4px;
    border-bottom-right-radius: 4px;
}

QComboBox::down-arrow:editable,
QDateTimeEdit::down-arrow:editable {
    qproperty-alignment: AlignTop;
    image: url(theme:Dark/collapse.svg);
    width: 100%;
}

/* Textedits etc */

QLineEdit,
QTextEdit,
QPlainTextEdit {
    background-color: var(--ctp_surface0);
    border-radius: var(--border_radius);
    padding: var(--input_padding) var(--padding_small) var(--input_padding) var(--input_padding);
    padding-left: 8px;
    border: 1px solid var(--ctp_surface0);
    height: var(--input_height);
}

QLineEdit:hover,
QTextEdit:hover,
QPlainTextEdit:hover {
    background-color: palette(mid);
    border-color: var(--ctp_surface2);
}

QLineEdit:focus,
QTextEdit:focus,
QPlainTextEdit:focus {
    background-color: palette(mid);
    border-color: var(--ctp_surface1);
}

QTextEdit:!editable,
QTextEdit:!editable:hover,
QTextEdit:!editable:focus {
    background-color: var(--ctp_surface0);
}

/* Spinbox and doubleSpinbox */

QSpinBox,
QDoubleSpinBox {
    background-color: var(--ctp_surface0);
    border: 1px solid var(--ctp_surface0);
    border-radius: var(--border_radius);
    padding: var(--input_padding) 0px var(--input_padding) var(--input_padding);
    padding-left: 8px;
    max-height: var(--spinbox_button_height);
}

QSpinBox:hover,
QDoubleSpinBox:hover {
    background-color: palette(mid);
    border-color: var(--ctp_surface2);
}

QSpinBox:focus,
QDoubleSpinBox:focus {
    background-color: palette(mid);
    border-color: var(--ctp_surface1);
}

QSpinBox::up-button,
QDoubleSpinBox::up-button {
    subcontrol-origin: padding;
    /* position at the top right corner */
    subcontrol-position: top right;

    width: var(--input_height);
    border-left: 1px solid var(--ctp_crust);
    border-bottom: 1px solid transparent;
    border-radius: 0px;
    border-top-right-radius: var(--border_radius_small);
}

QSpinBox::down-button,
QDoubleSpinBox::down-button {
    subcontrol-origin: padding;
    /* position at the top right corner */
    subcontrol-position: bottom right;

    width: var(--input_height);
    border-left: 1px solid var(--ctp_crust);
    border-top: 1px solid transparent;
    border-radius: 0px;
    border-bottom-right-radius: var(--border_radius_small);
}

QSpinBox::up-button:hover,
QSpinBox::down-button:hover,
QDoubleSpinBox::up-button:hover,
QDoubleSpinBox::down-button:hover {
    background-color: var(--ctp_surface1);
}

QSpinBox::up-button:pressed,
QSpinBox::down-button:pressed,
QDoubleSpinBox::up-button:pressed,
QDoubleSpinBox::down-button:pressed {
    background-color: var(--ctp_crust);
}

QSpinBox::up-button:disabled,
QSpinBox::up-button:off,
QSpinBox::down-button:disabled,
QSpinBox::down-button:off {
    background-color: var(--ctp_crust);
}

QDoubleSpinBox::up-button:disabled,
QDoubleSpinBox::up-button:off,
QDoubleSpinBox::down-button:disabled,
QDoubleSpinBox::down-button:off {
    background-color: var(--ctp_crust);
}

QSpinBox::up-arrow,
QDoubleSpinBox::up-arrow {
    image: url(theme:Dark/up.svg);
    width: 100%;
    margin: 2px;
}

QSpinBox::down-arrow,
QDoubleSpinBox::down-arrow {
    image: url(theme:Dark/down.svg);
    width: 100%;
    padding: 2px;
}

/* Controls Dock */
#controlsFrame {
    padding: var(--padding_large);
}

#controlsFrame QPushButton {
    margin: var(--spacing_base) var(--spacing_small);
}

#streamButton,
#recordButton,
#replayBufferButton,
#broadcastButton {
    padding: var(--padding_large);
}

#pauseRecordButton,
#saveReplayButton,
#virtualCamConfigButton {
    padding: var(--padding_large) var(--padding_large);
    width: var(--input_height);
    max-width: var(--input_height);
}

/* Primary Control Button Checked Coloring */
#streamButton:!hover:!pressed.state-active,
#recordButton:!hover:!pressed.state-active,
#replayBufferButton:!hover:!pressed.state-active,
#virtualCamButton:!hover:!pressed.state-active,
#modeSwitch:!hover:!pressed.state-active,
#broadcastButton:!hover:!pressed.state-active {
    background: var(--ctp_blue);
    color: var(--ctp_crust);
}

/* Primary Control Button Hover Coloring */
#streamButton:hover:!pressed.state-active,
#recordButton:hover:!pressed.state-active,
#replayBufferButton:!pressed.state-active,
#virtualCamButton:!pressed.state-active,
#modeSwitch:hover:!pressed.state-active,
#broadcastButton:hover:!pressed.state-active {
    background: var(--ctp_lavender);
    color: var(--ctp_crust);
}


/* Buttons */

QPushButton {
    color: palette(text);
    background-color: palette(button);
    border-radius: var(--border_radius);
    height: var(--input_height);
    max-height: var(--input_height);
    padding: var(--input_padding) var(--padding_wide);
    icon-size: var(--icon_base);
}

QPushButton {
    border: 1px solid palette(button);
}

QToolButton {
    border: 1px solid palette(button);
}

QToolButton,
.btn-tool {
    background-color: palette(button);
    padding: var(--padding_base) var(--padding_base);
    margin: 0px var(--spacing_base);
    border: 1px solid transparent;
    border-radius: var(--border_radius);
    icon-size: var(--icon_base);
}

QToolButton:last-child,
.btn-tool:last-child {
    margin-right: 0px;
}

QPushButton:hover,
QPushButton:focus {
    border-color: var(--ctp_surface1);
}

QPushButton:hover {
    background-color: var(--ctp_surface1);
}

QToolButton:hover,
QToolButton:focus,
.btn-tool:hover,
.btn-tool:focus,
.indicator-mute::indicator:hover,
.indicator-mute::indicator:focus {
    border-color: var(--ctp_surface1);
    background-color: var(--ctp_surface1);
}

QPushButton::flat {
    background-color: var(--ctp_surface0);
}

QPushButton:checked {
    background-color: var(--ctp_surface1);
}

QPushButton:checked:hover,
QPushButton:checked:focus {
    background-color: var(--ctp_surface1);
}

QToolButton:pressed,
QToolButton:pressed:hover {
    background-color: var(--ctp_crust);
    border-color: var(--ctp_crust);
}

QPushButton:pressed,
QPushButton:pressed:hover,
.btn-tool:pressed,
.btn-tool:pressed:hover {
    background-color: var(--ctp_crust);
    border-color: var(--ctp_crust);
}

QPushButton:disabled {
    background-color: var(--ctp_crust);
    border-color: var(--ctp_crust);
}

QToolButton:disabled,
.btn-tool:disabled {
    background-color: transparent;
    border-color: transparent;
}

QPushButton::menu-indicator {
    image: url(theme:Dark/down.svg);
    subcontrol-position: right;
    subcontrol-origin: padding;
    width: 25px;
}

/* Sliders */

QSlider::groove {
    background-color: var(--ctp_surface0);
    border: none;
    border-radius: 2px;
}

QSlider::groove:horizontal {
    height: 4px;
}

QSlider::groove:vertical {
    width: 4px;
}

QSlider::sub-page:horizontal {
    background-color: palette(highlight);
    border-radius: 2px;
}

QSlider::sub-page:horizontal:disabled {
    background-color: palette(window);
    border-radius: 2px;
}

QSlider::add-page:horizontal:disabled {
    background-color: var(--ctp_crust);
    border-radius: 2px;
}

QSlider::add-page:vertical {
    background-color: palette(highlight);
    border-radius: 2px;
}

QSlider::add-page:vertical:disabled {
    background-color: palette(window);
    border-radius: 2px;
}

QSlider::sub-page:vertical:disabled {
    background-color: var(--ctp_crust);
    border-radius: 2px;
}

QSlider::handle {
    background-color: palette(text);
    border-radius: var(--border_radius);
}

QSlider::handle:horizontal {
    height: 10px;
    width: 20px;
    /* Handle is placed by default on the contents rect of the groove. Expand outside the groove */
    margin: -3px 0;
}

QSlider::handle:vertical {
    width: 10px;
    height: 20px;
    /* Handle is placed by default on the contents rect of the groove. Expand outside the groove */
    margin: 0 -3px;
}

QSlider::handle:hover {
    background-color: var(--ctp_subtext1);
}

QSlider::handle:pressed {
    background-color: var(--ctp_overlay1);
}

QSlider::handle:disabled {
    background-color: var(--ctp_overlay1);
}

/* Volume Control */

#stackedMixerArea QPushButton {
    width: var(--icon_base);
    height: var(--icon_base);
    background-color: var(--ctp_surface0);
    padding: var(--padding_base_border) var(--padding_base_border);
    margin: 0px;
    border: 1px solid transparent;
    border-radius: var(--border_radius);
    icon-size: var(--icon_base);
}

/* This is an incredibly cursed but necessary fix */
#stackedMixerArea QPushButton:!hover {
    background-color: palette(base);
}

#stackedMixerArea QPushButton:hover {
    background-color: var(--ctp_surface1);
    border-color: var(--ctp_surface1);
}

#stackedMixerArea QPushButton:pressed {
    background-color: var(--ctp_crust);
}

#stackedMixerArea {
    border: none;
    padding: 0px;
    border-bottom: 1px solid palette(window);
}

VolControl #volLabel {
    padding: var(--padding_base) 0px var(--padding_base);
    text-align: center;
    font-size: var(--font_base);
    color: var(--ctp_overlay1);
}

/* Horizontal Mixer */
#hMixerScrollArea VolControl {
    padding: 0px var(--padding_xlarge) var(--padding_base);
    border-bottom: 1px solid var(--ctp_surface0);
}

#hMixerScrollArea VolControl QSlider {
    margin: 0px 0px var(--padding_base);
}

#hMixerScrollArea VolControl QSlider::groove:horizontal {
    background: palette(window);
    height: var(--volume_slider);
}

/* Vertical Mixer */
#stackedMixerArea QScrollBar:vertical {
    border-left: 1px solid var(--ctp_surface0);
}

#vMixerScrollArea VolControl {
    padding: var(--padding_large) 0px var(--padding_base);
    border-right: 1px solid var(--ctp_surface0);
}

#vMixerScrollArea VolControl QSlider {
    width: var(--volume_slider_box);
    margin: 0px var(--padding_xlarge);
}

#vMixerScrollArea VolControl #volLabel {
    padding: var(--padding_base) 0px var(--padding_base);
    min-width: var(--volume_slider_label);
    margin-left: var(--padding_xlarge);
    text-align: center;
}

#vMixerScrollArea VolControl QSlider::groove:vertical {
    background: palette(window);
    width: var(--volume_slider);
}

#vMixerScrollArea VolControl #volMeterFrame {
    padding: var(--padding_large) var(--padding_xlarge) var(--padding_large) 0px;
}

#vMixerScrollArea VolControl QLabel {
    padding: 0px var(--padding_large);
}

#vMixerScrollArea VolControl QPushButton {
    margin-right: var(--padding_xlarge);
}

#vMixerScrollArea VolControl .indicator-mute {
    margin-left: var(--padding_xlarge);
}

VolControl {
    background: palette(base);
}

VolumeMeter {
    background: transparent;
}

VolumeMeter {
    qproperty-backgroundNominalColor: var(--ctp_green);
    qproperty-backgroundWarningColor: var(--ctp_peach);
    qproperty-backgroundErrorColor: var(--ctp_red);
    qproperty-foregroundNominalColor: var(--ctp_green);
    qproperty-foregroundWarningColor: var(--ctp_peach);
    qproperty-foregroundErrorColor: var(--ctp_red);

    qproperty-backgroundNominalColorDisabled: var(--ctp_surface0);
    qproperty-backgroundWarningColorDisabled: var(--ctp_overlay0);
    qproperty-backgroundErrorColorDisabled: var(--ctp_subtext1);
    qproperty-foregroundNominalColorDisabled: var(--ctp_surface1);
    qproperty-foregroundWarningColorDisabled: var(--ctp_overlay1);
    qproperty-foregroundErrorColorDisabled: var(--ctp_subtext0);

    qproperty-magnitudeColor: var(--ctp_surface0);
    qproperty-majorTickColor: var(--ctp_text);
    qproperty-minorTickColor: var(--ctp_overlay0);
    qproperty-peakDecayRate: 23.4;
}

/* Status Bar */

QStatusBar::item {
    border: none;
}

/* Table View */

QTableView {
    background: palette(base);
    gridline-color: palette(light);
}

QTableView::item {
    margin: 0px;
    padding: 0px;
}

QTableView QLineEdit {
    background: palette(mid);
    padding: 0;
    margin: 0;
}

QTableView QPushButton,
QTableView QToolButton {
    padding: 0px;
    margin: -1px;
    border_radius: 0px;
}

QHeaderView::section {
    background-color: var(--ctp_surface0);
    color: palette(text);
    border: none;
    border-left: 1px solid palette(window);
    border-right: 1px solid palette(window);
    padding: 3px 0px;
    margin-bottom: 2px;
}

/* Canvas / Preview background color */

OBSQTDisplay {
    qproperty-displayBackgroundColor: var(--ctp_crust);
}

/* Filters Window */

OBSBasicFilters QListWidget {
    border-radius: var(--border_radius_large);
    padding: var(--spacing_base);
}

OBSBasicFilters QListWidget::item {
    border-radius: var(--border_radius);
    padding: var(--padding_base) var(--padding_large);
}

OBSBasicFilters #widget,
OBSBasicFilters #widget_2 {
    margin: 0px;
    padding: 0px;
    padding-bottom: var(--padding_base);
}

OBSBasicFilters #widget QPushButton,
OBSBasicFilters #widget_2 QPushButton {
    min-width: 16px;
    padding: var(--padding_base) var(--padding_large);
    margin-top: 0px;
}

/* Preview/Program labels */

.label-preview-title {
    font-size: var(--font_xlarge);
    font-weight: bold;
    color: var(--ctp_subtext0);
    margin-bottom: 4px;
}

/* Settings Icons */

OBSBasicSettings {
    qproperty-generalIcon: url(theme:Dark/settings/general.svg);
    qproperty-appearanceIcon: url(theme:Dark/settings/appearance.svg);
    qproperty-streamIcon: url(theme:Dark/settings/stream.svg);
    qproperty-outputIcon: url(theme:Dark/settings/output.svg);
    qproperty-audioIcon: url(theme:Dark/settings/audio.svg);
    qproperty-videoIcon: url(theme:Dark/settings/video.svg);
    qproperty-hotkeysIcon: url(theme:Dark/settings/hotkeys.svg);
    qproperty-accessibilityIcon: url(theme:Dark/settings/accessibility.svg);
    qproperty-advancedIcon: url(theme:Dark/settings/advanced.svg);
}

/* Checkboxes */

QCheckBox::indicator,
QGroupBox::indicator {
    width: var(--icon_base);
    height: var(--icon_base);
}

QGroupBox::indicator {
    margin-left: 2px;
}

QCheckBox::indicator:unchecked,
QGroupBox::indicator:unchecked {
    image: url(theme:Yami/checkbox_unchecked.svg);
}

QCheckBox::indicator:unchecked:hover,
QGroupBox::indicator:unchecked:hover {
    border: none;
    image: url(theme:Yami/checkbox_unchecked_focus.svg);
}

QCheckBox::indicator:checked,
QGroupBox::indicator:checked {
    image: url(theme:Yami/checkbox_checked.svg);
}

QCheckBox::indicator:checked:hover,
QGroupBox::indicator:checked:hover {
    image: url(theme:Yami/checkbox_checked_focus.svg);
}

QCheckBox::indicator:checked:disabled,
QGroupBox::indicator:checked:disabled {
    image: url(theme:Yami/checkbox_checked_disabled.svg);
}

QCheckBox::indicator:unchecked:disabled,
QGroupBox::indicator:unchecked:disabled {
    image: url(theme:Yami/checkbox_unchecked_disabled.svg);
}

/* Icon Checkboxes */
.checkbox-icon {
    outline: none;
    background: transparent;
    max-width: var(--icon_base);
    max-height: var(--icon_base);
    padding: var(--padding_base);
    margin-right: var(--spacing_large);
    border: 1px solid transparent;
    border-radius: 4px;
}

.checkbox-icon::indicator {
    width: var(--icon_base);
    height: var(--icon_base);
}

.checkbox-icon:hover,
.checkbox-icon:focus {
    border-color: var(--border_highlight);
}

/* Locked CheckBox */

.indicator-lock::indicator:checked,
.indicator-lock::indicator:checked:hover {
    image: url(theme:Dark/locked.svg);
}

.indicator-lock::indicator:unchecked,
.indicator-lock::indicator:unchecked:hover {
    image: url(:res/images/unlocked.svg);
}

/* Visibility CheckBox */

.indicator-visibility::indicator:checked,
.indicator-visibility::indicator:checked:hover {
    image: url(theme:Dark/visible.svg);
}

.indicator-visibility::indicator:unchecked,
.indicator-visibility::indicator:unchecked:hover {
    image: url(:res/images/invisible.svg);
}

/* Mute CheckBox */

.indicator-mute {
    outline: none;
}

.indicator-mute::indicator,
.indicator-mute::indicator:unchecked {
    width: var(--icon_base);
    height: var(--icon_base);
    background-color: palette(button);
    padding: var(--padding_base_border) var(--padding_base_border);
    margin: 0px;
    border: 1px solid transparent;
    border-radius: var(--border_radius);
    icon-size: var(--icon_base);
}

.indicator-mute::indicator:hover,
.indicator-mute::indicator:unchecked:hover {
    background-color: palette(mid);
    padding: var(--padding_base_border) var(--padding_base_border);
    margin: 0px;
    border: 1px solid var(--ctp_surface1);
    icon-size: var(--icon_base);
}

.indicator-mute::indicator:pressed,
.indicator-mute::indicator:pressed:hover {
    background-color: palette(mid);
    border-color: var(--ctp_surface1);
}

.indicator-mute::indicator:checked {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:indeterminate {
    image: url(theme:Dark/unassigned.svg);
}

.indicator-mute::indicator:unchecked {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:hover {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:focus {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:checked:hover {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:focus {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:disabled {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:unchecked:disabled {
    image: url(theme:Dark/settings/audio.svg);
}

#hotkeyFilterReset {
    margin-top: 0px;
}

OBSHotkeyWidget {
    padding: 8px 0px;
    margin: 2px 0px;
}

OBSHotkeyLabel {
    padding: 4px 0px;
}

OBSHotkeyWidget QPushButton {
    min-width: 16px;
    padding: var(--padding_base);
    margin-top: 0px;
    margin-left: var(--spacing_base);
}


/* Sources List Group Collapse Checkbox */

.indicator-expand::indicator:checked,
.indicator-expand::indicator:checked:hover {
    image: url(theme:Dark/expand.svg);
}

.indicator-expand::indicator:unchecked,
.indicator-expand::indicator:unchecked:hover {
    image: url(theme:Dark/collapse.svg);
}

/* Source Icons */

OBSBasic {
    qproperty-imageIcon: url(theme:Dark/sources/image.svg);
    qproperty-colorIcon: url(theme:Dark/sources/brush.svg);
    qproperty-slideshowIcon: url(theme:Dark/sources/slideshow.svg);
    qproperty-audioInputIcon: url(theme:Dark/sources/microphone.svg);
    qproperty-audioOutputIcon: url(theme:Dark/settings/audio.svg);
    qproperty-desktopCapIcon: url(theme:Dark/settings/video.svg);
    qproperty-windowCapIcon: url(theme:Dark/sources/window.svg);
    qproperty-gameCapIcon: url(theme:Dark/sources/gamepad.svg);
    qproperty-cameraIcon: url(theme:Dark/sources/camera.svg);
    qproperty-textIcon: url(theme:Dark/sources/text.svg);
    qproperty-mediaIcon: url(theme:Dark/sources/media.svg);
    qproperty-browserIcon: url(theme:Dark/sources/globe.svg);
    qproperty-groupIcon: url(theme:Dark/sources/group.svg);
    qproperty-sceneIcon: url(theme:Dark/sources/scene.svg);
    qproperty-defaultIcon: url(theme:Dark/sources/default.svg);
    qproperty-audioProcessOutputIcon: url(theme:Dark/sources/windowaudio.svg);
}

/* Scene Tree Grid Mode */

SceneTree {
    qproperty-gridItemWidth: 154;
    qproperty-gridItemHeight: var(--input_height_base);
}

.list-grid SceneTree::item {
    color: palette(text);
    background-color: palette(button);
    border-radius: var(--border_radius);
    margin: var(--spacing_base);
}

.list-grid SceneTree::item:selected {
    background-color: var(--ctp_surface1);
}

.list-grid SceneTree::item:checked {
    background-color: var(--ctp_surface1);
}

.list-grid SceneTree::item:hover {
    background-color: var(--ctp_surface1);
}

.list-grid SceneTree::item:selected:hover {
    background-color: var(--ctp_surface1);
}

/* Studio Mode T-Bar */

.slider-tbar {
    height: 24px;
}

.slider-tbar::groove:horizontal {
    height: 8px;
}

.slider-tbar::sub-page:horizontal {
    background: var(--ctp_blue);
}

.slider-tbar::handle:horizontal {
    width: 12px;
    height: 24px;
    margin: -24px 0px;
}

/* YouTube Integration */
OBSYoutubeActions {
    qproperty-thumbPlaceholder: url(theme:Dark/sources/image.svg);
}

#ytEventList QLabel {
    color: palette(text);
    background-color: var(--ctp_surface0);
    border: none;
    border-radius: var(--border_radius);
    padding: 4px 20px;
}

#ytEventList QLabel:hover {
    background-color: var(--ctp_surface1);
}

#ytEventList .row-selected {
    background-color: var(--ctp_surface1);
    border: none;
}

#ytEventList .row-selected:hover {
    background-color: var(--ctp_blue);
    color: palette(text);
}

/* Calendar Widget */
QDateTimeEdit::down-arrow {
    qproperty-alignment: AlignTop;
    image: url(theme:Dark/down.svg);
    width: 100%;
}

QDateTimeEdit:on {
    background-color: palette(mid);
}

/* Calendar Top Bar */
QCalendarWidget QWidget#qt_calendar_navigationbar {
    background-color: palette(base);
    padding: var(--padding_base) var(--padding_large);
}

/* Calendar Top Bar Buttons */
QCalendarWidget QToolButton {
    background-color: palette(base);
    padding: 2px 16px;
    border-radius: var(--border_radius);
    margin: var(--spacing_base);
}

#qt_calendar_monthbutton::menu-indicator {
    image: url(theme:Dark/down.svg);
    subcontrol-position: right;
    padding-top: var(--padding_small);
    padding-right: var(--padding_base);
    height: 10px;
    width: 10px;
}

QCalendarWidget #qt_calendar_prevmonth {
    padding: var(--padding_small);
    qproperty-icon: url(theme:Dark/left.svg);
    icon-size: var(--icon_base);
}

QCalendarWidget #qt_calendar_nextmonth {
    padding: var(--padding_small);
    qproperty-icon: url(theme:Dark/right.svg);
    icon-size: var(--icon_base);
}

QCalendarWidget QToolButton:hover {
    background-color: var(--ctp_surface1);
    border-radius: var(--border_radius);
}

QCalendarWidget QToolButton:pressed {
    background-color: var(--ctp_crust);
}

/* Month Dropdown Menu */
QCalendarWidget QMenu {}

/* Year spinbox */
QCalendarWidget QSpinBox {
    background-color: var(--ctp_crust);
    border: none;
    border-radius: var(--border_radius);
    margin: 0px var(--spacing_base) 0px 0px;
    padding: var(--padding_base) 16px;
}

QCalendarWidget QSpinBox::up-button {
    subcontrol-origin: border;
    subcontrol-position: top right;
    width: 16px;
}

QCalendarWidget QSpinBox::down-button {
    subcontrol-origin: border;
    subcontrol-position: bottom right;
    width: 16px;
}

QCalendarWidget QSpinBox::up-arrow {
    width: 10px;
    height: 10px;
}

QCalendarWidget QSpinBox::down-arrow {
    width: 10px;
    height: 10px;
}

/* Days of the Week Bar */
QCalendarWidget QWidget {
    alternate-background-color: palette(mid);
}

QCalendarWidget QAbstractItemView:enabled {
    background-color: palette(base);
    color: palette(text);
}

QCalendarWidget QAbstractItemView:disabled {
    color: var(--ctp_overlay1);
}

/* VirtualCam Plugin Fixes */

#VirtualProperties QWidget {
    margin-top: 0;
    margin-bottom: 0;
}

/* Disable icons on QDialogButtonBox */
QDialogButtonBox {
    dialogbuttonbox-buttons-have-icons: 0;
}

/* Stats dialog */
OBSBasicStats {
    background: palette(dark);
}

/* Advanced audio dialog */
OBSBasicAdvAudio #scrollAreaWidgetContents {
    background: palette(dark);
}

#previewScalePercent,
#previewScalingMode {
    background: transparent;
    color: var(--ctp_text);
    font-size: var(--font_xsmall);
    height: 14px;
    max-height: 14px;
    padding: 0px var(--padding_xlarge);
    margin: 0;
    border: none;
    border-radius: 0;
}

#previewXContainer {
    border: 1px solid var(--ctp_base);
}

#previewScalingMode {
    border: 1px solid var(--ctp_base);
}

#previewScalingMode:hover,
#previewScalingMode:focus {
    border-color: var(--ctp_base);
}

#previewXScrollBar,
#previewYScrollBar {
    background: transparent;
    border: 1px solid var(--ctp_base);
    border-radius: 0;
}

#previewXScrollBar {
    border-left: none;
    height: 16px;
}

#previewXScrollBar::handle,
#previewYScrollBar::handle {
    margin: 3px;
}

#previewYScrollBar {
    width: 16px;
}
    '';
    "obs-studio/themes/Catppuccin_Frappe.ovt".text = ''
@OBSThemeMeta {
    name: 'Frappe';
    id: 'com.obsproject.Catppuccin.Frappe';
    extends: 'com.obsproject.Catppuccin';
    author: 'Xurdejl';
    dark: 'true';
}

@OBSThemeVars {
    --ctp_rosewater: #f2d5cf;
    --ctp_flamingo: #eebebe;
    --ctp_pink: #f4b8e4;
    --ctp_mauve: #ca9ee6;
    --ctp_red: #e78284;
    --ctp_maroon: #ea999c;
    --ctp_peach: #ef9f76;
    --ctp_yellow: #e5c890;
    --ctp_green: #a6d189;
    --ctp_teal: #81c8be;
    --ctp_sky: #99d1db;
    --ctp_sapphire: #85c1dc;
    --ctp_blue: #8caaee;
    --ctp_lavender: #babbf1;
    --ctp_text: #c6d0f5;
    --ctp_subtext1: #b5bfe2;
    --ctp_subtext0: #a5adce;
    --ctp_overlay2: #949cbb;
    --ctp_overlay1: #838ba7;
    --ctp_overlay0: #737994;
    --ctp_surface2: #626880;
    --ctp_surface1: #51576d;
    --ctp_surface0: #414559;
    --ctp_base: #303446;
    --ctp_mantle: #292c3c;
    --ctp_crust: #232634;
    --ctp_selection_background: #44495d;
}

VolumeMeter {
    qproperty-foregroundNominalColor: #7cbc52;
    qproperty-foregroundWarningColor: #e76f33;
    qproperty-foregroundErrorColor: #db4346;
}

/* Icon Overrides */

.icon-plus {
    qproperty-icon: url(theme:Dark/plus.svg);
}

.icon-minus {
    qproperty-icon: url(theme:Dark/minus.svg);
}

.icon-trash {
    qproperty-icon: url(theme:Dark/trash.svg);
}

.icon-clear {
    qproperty-icon: url(theme:Dark/entry-clear.svg);
}

.icon-gear {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

.icon-dots-vert {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

.icon-refresh {
    qproperty-icon: url(theme:Dark/refresh.svg);
}

.icon-cogs {
    qproperty-icon: url(theme:Dark/cogs.svg);
}

.icon-touch {
    qproperty-icon: url(theme:Dark/interact.svg);
}

.icon-up {
    qproperty-icon: url(theme:Dark/up.svg);
}

.icon-down {
    qproperty-icon: url(theme:Dark/down.svg);
}

.icon-pause {
    qproperty-icon: url(theme:Dark/media-pause.svg);
}

.icon-filter {
    qproperty-icon: url(theme:Dark/filter.svg);
}

.icon-revert {
    qproperty-icon: url(theme:Dark/revert.svg);
}

.icon-save {
    qproperty-icon: url(theme:Dark/save.svg);
}

/* Media icons */

.icon-media-play {
    qproperty-icon: url(theme:Dark/media/media_play.svg);
}

.icon-media-pause {
    qproperty-icon: url(theme:Dark/media/media_pause.svg);
}

.icon-media-restart {
    qproperty-icon: url(theme:Dark/media/media_restart.svg);
}

.icon-media-stop {
    qproperty-icon: url(theme:Dark/media/media_stop.svg);
}

.icon-media-next {
    qproperty-icon: url(theme:Dark/media/media_next.svg);
}

.icon-media-prev {
    qproperty-icon: url(theme:Dark/media/media_previous.svg);
}

/* Context Menu */
QMenu::right-arrow {
    image: url(theme:Dark/expand.svg);
}

/* Dock Widget */
QDockWidget {
    titlebar-close-icon: url(theme:Dark/close.svg);
    titlebar-normal-icon: url(theme:Dark/popout.svg);
}

/* Source Context Bar */
QPushButton#sourcePropertiesButton {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

QPushButton#sourceFiltersButton {
    qproperty-icon: url(theme:Dark/filter.svg);
}

/* Scenes and Sources toolbar */
QToolBarExtension {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

/* ComboBox */
QComboBox::down-arrow,
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/collapse.svg);
}

QComboBox::down-arrow:editable,
QDateTimeEdit::down-arrow:editable {
    image: url(theme:Dark/collapse.svg);
}

/* Spinbox and doubleSpinbox */
QSpinBox::up-arrow,
QDoubleSpinBox::up-arrow {
    image: url(theme:Dark/up.svg);
}

QSpinBox::down-arrow,
QDoubleSpinBox::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Buttons */
QPushButton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

/* Settings Icons */
OBSBasicSettings {
    qproperty-generalIcon: url(theme:Dark/settings/general.svg);
    qproperty-appearanceIcon: url(theme:Dark/settings/appearance.svg);
    qproperty-streamIcon: url(theme:Dark/settings/stream.svg);
    qproperty-outputIcon: url(theme:Dark/settings/output.svg);
    qproperty-audioIcon: url(theme:Dark/settings/audio.svg);
    qproperty-videoIcon: url(theme:Dark/settings/video.svg);
    qproperty-hotkeysIcon: url(theme:Dark/settings/hotkeys.svg);
    qproperty-accessibilityIcon: url(theme:Dark/settings/accessibility.svg);
    qproperty-advancedIcon: url(theme:Dark/settings/advanced.svg);
}

/* Checkboxes */
QCheckBox::indicator:unchecked,
QGroupBox::indicator:unchecked {
    image: url(theme:Yami/checkbox_unchecked.svg);
}

QCheckBox::indicator:unchecked:hover,
QGroupBox::indicator:unchecked:hover {
    border: none;
    image: url(theme:Yami/checkbox_unchecked_focus.svg);
}

QCheckBox::indicator:checked,
QGroupBox::indicator:checked {
    image: url(theme:Yami/checkbox_checked.svg);
}

QCheckBox::indicator:checked:hover,
QGroupBox::indicator:checked:hover {
    image: url(theme:Yami/checkbox_checked_focus.svg);
}

QCheckBox::indicator:checked:disabled,
QGroupBox::indicator:checked:disabled {
    image: url(theme:Yami/checkbox_checked_disabled.svg);
}

/* Locked CheckBox */
.indicator-lock::indicator:checked,
.indicator-lock::indicator:checked:hover {
    image: url(theme:Dark/locked.svg);
}

/* Visibility CheckBox */
.indicator-visibility::indicator:checked,
.indicator-visibility::indicator:checked:hover {
    image: url(theme:Dark/visible.svg);
}

/* Mute CheckBox */
.indicator-mute::indicator:checked {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:indeterminate {
    image: url(theme:Dark/unassigned.svg);
}

.indicator-mute::indicator:unchecked {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:hover {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:focus {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:checked:hover {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:focus {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:disabled {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:unchecked:disabled {
    image: url(theme:Dark/settings/audio.svg);
}

/* Sources List Group Collapse Checkbox */
.indicator-expand::indicator:checked,
.indicator-expand::indicator:checked:hover {
    image: url(theme:Dark/expand.svg);
}

.indicator-expand::indicator:unchecked,
.indicator-expand::indicator:unchecked:hover {
    image: url(theme:Dark/collapse.svg);
}

/* Source Icons */
OBSBasic {
    qproperty-imageIcon: url(theme:Dark/sources/image.svg);
    qproperty-colorIcon: url(theme:Dark/sources/brush.svg);
    qproperty-slideshowIcon: url(theme:Dark/sources/slideshow.svg);
    qproperty-audioInputIcon: url(theme:Dark/sources/microphone.svg);
    qproperty-audioOutputIcon: url(theme:Dark/settings/audio.svg);
    qproperty-desktopCapIcon: url(theme:Dark/settings/video.svg);
    qproperty-windowCapIcon: url(theme:Dark/sources/window.svg);
    qproperty-gameCapIcon: url(theme:Dark/sources/gamepad.svg);
    qproperty-cameraIcon: url(theme:Dark/sources/camera.svg);
    qproperty-textIcon: url(theme:Dark/sources/text.svg);
    qproperty-mediaIcon: url(theme:Dark/sources/media.svg);
    qproperty-browserIcon: url(theme:Dark/sources/globe.svg);
    qproperty-groupIcon: url(theme:Dark/sources/group.svg);
    qproperty-sceneIcon: url(theme:Dark/sources/scene.svg);
    qproperty-defaultIcon: url(theme:Dark/sources/default.svg);
    qproperty-audioProcessOutputIcon: url(theme:Dark/sources/windowaudio.svg);
}

/* YouTube Integration */
OBSYoutubeActions {
    qproperty-thumbPlaceholder: url(theme:Dark/sources/image.svg);
}

/* Calendar Widget */
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Calendar Top Bar Buttons */
#qt_calendar_monthbutton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

QCalendarWidget #qt_calendar_prevmonth {
    qproperty-icon: url(theme:Dark/left.svg);
}

QCalendarWidget #qt_calendar_nextmonth {
    qproperty-icon: url(theme:Dark/right.svg);
}
    '';
    "obs-studio/themes/Catppuccin_Latte.ovt".text = ''
@OBSThemeMeta {
    name: 'Latte';
    id: 'com.obsproject.Catppuccin.Latte';
    extends: 'com.obsproject.Catppuccin';
    author: 'Xurdejl';
    dark: 'false';
}

@OBSThemeVars {
    --ctp_rosewater: #dc8a78;
    --ctp_flamingo: #dd7878;
    --ctp_pink: #ea76cb;
    --ctp_mauve: #8839ef;
    --ctp_red: #d20f39;
    --ctp_maroon: #e64553;
    --ctp_peach: #fe640b;
    --ctp_yellow: #df8e1d;
    --ctp_green: #40a02b;
    --ctp_teal: #179299;
    --ctp_sky: #04a5e5;
    --ctp_sapphire: #209fb5;
    --ctp_blue: #1e66f5;
    --ctp_lavender: #7287fd;
    --ctp_text: #4c4f69;
    --ctp_subtext1: #5c5f77;
    --ctp_subtext0: #6c6f85;
    --ctp_overlay2: #7c7f93;
    --ctp_overlay1: #8c8fa1;
    --ctp_overlay0: #9ca0b0;
    --ctp_surface2: #acb0be;
    --ctp_surface1: #bcc0cc;
    --ctp_surface0: #ccd0da;
    --ctp_base: #eff1f5;
    --ctp_mantle: #e6e9ef;
    --ctp_crust: #dce0e8;
    --ctp_selection_background: #d4d7df;
}

VolumeMeter {
    qproperty-foregroundNominalColor: #62ce4a;
    qproperty-foregroundWarningColor: #fe9558;
    qproperty-foregroundErrorColor: #f13d64;
}

/* Icon Overrides */

.icon-plus {
    qproperty-icon: url(theme:Light/plus.svg);
}

.icon-minus {
    qproperty-icon: url(theme:Light/minus.svg);
}

.icon-trash {
    qproperty-icon: url(theme:Light/trash.svg);
}

.icon-clear {
    qproperty-icon: url(theme:Light/entry-clear.svg);
}

.icon-gear {
    qproperty-icon: url(theme:Light/settings/general.svg);
}

.icon-dots-vert {
    qproperty-icon: url(theme:Light/dots-vert.svg);
}

.icon-refresh {
    qproperty-icon: url(theme:Light/refresh.svg);
}

.icon-cogs {
    qproperty-icon: url(theme:Light/cogs.svg);
}

.icon-touch {
    qproperty-icon: url(theme:Light/interact.svg);
}

.icon-up {
    qproperty-icon: url(theme:Light/up.svg);
}

.icon-down {
    qproperty-icon: url(theme:Light/down.svg);
}

.icon-pause {
    qproperty-icon: url(theme:Light/media-pause.svg);
}

.icon-filter {
    qproperty-icon: url(theme:Light/filter.svg);
}

.icon-revert {
    qproperty-icon: url(theme:Light/revert.svg);
}

.icon-save {
    qproperty-icon: url(theme:Light/save.svg);
}

/* Media icons */

.icon-media-play {
    qproperty-icon: url(theme:Light/media/media_play.svg);
}

.icon-media-pause {
    qproperty-icon: url(theme:Light/media/media_pause.svg);
}

.icon-media-restart {
    qproperty-icon: url(theme:Light/media/media_restart.svg);
}

.icon-media-stop {
    qproperty-icon: url(theme:Light/media/media_stop.svg);
}

.icon-media-next {
    qproperty-icon: url(theme:Light/media/media_next.svg);
}

.icon-media-prev {
    qproperty-icon: url(theme:Light/media/media_previous.svg);
}

/* Context Menu */
QMenu::right-arrow {
    image: url(theme:Light/expand.svg);
}

/* Dock Widget */
QDockWidget {
    titlebar-close-icon: url(theme:Light/close.svg);
    titlebar-normal-icon: url(theme:Light/popout.svg);
}

/* Source Context Bar */
QPushButton#sourcePropertiesButton {
    qproperty-icon: url(theme:Light/settings/general.svg);
}

QPushButton#sourceFiltersButton {
    qproperty-icon: url(theme:Light/filter.svg);
}

/* Scenes and Sources toolbar */
QToolBarExtension {
    qproperty-icon: url(theme:Light/dots-vert.svg);
}

/* ComboBox */
QComboBox::down-arrow,
QDateTimeEdit::down-arrow {
    image: url(theme:Light/collapse.svg);
}

QComboBox::down-arrow:editable,
QDateTimeEdit::down-arrow:editable {
    image: url(theme:Light/collapse.svg);
}

/* Spinbox and doubleSpinbox */
QSpinBox::up-arrow,
QDoubleSpinBox::up-arrow {
    image: url(theme:Light/up.svg);
}

QSpinBox::down-arrow,
QDoubleSpinBox::down-arrow {
    image: url(theme:Light/down.svg);
}

/* Buttons */
QPushButton::menu-indicator {
    image: url(theme:Light/down.svg);
}

/* Settings Icons */
OBSBasicSettings {
    qproperty-generalIcon: url(theme:Light/settings/general.svg);
    qproperty-appearanceIcon: url(theme:Light/settings/appearance.svg);
    qproperty-streamIcon: url(theme:Light/settings/stream.svg);
    qproperty-outputIcon: url(theme:Light/settings/output.svg);
    qproperty-audioIcon: url(theme:Light/settings/audio.svg);
    qproperty-videoIcon: url(theme:Light/settings/video.svg);
    qproperty-hotkeysIcon: url(theme:Light/settings/hotkeys.svg);
    qproperty-accessibilityIcon: url(theme:Light/settings/accessibility.svg);
    qproperty-advancedIcon: url(theme:Light/settings/advanced.svg);
}

/* Checkboxes */
QCheckBox::indicator:unchecked,
QGroupBox::indicator:unchecked {
    image: url(theme:Light/checkbox_unchecked.svg);
}

QCheckBox::indicator:unchecked:hover,
QGroupBox::indicator:unchecked:hover {
    border: none;
    image: url(theme:Light/checkbox_unchecked_focus.svg);
}

QCheckBox::indicator:checked,
QGroupBox::indicator:checked {
    image: url(theme:Light/checkbox_checked.svg);
}

QCheckBox::indicator:checked:hover,
QGroupBox::indicator:checked:hover {
    image: url(theme:Light/checkbox_checked_focus.svg);
}

QCheckBox::indicator:checked:disabled,
QGroupBox::indicator:checked:disabled {
    image: url(theme:Light/checkbox_checked_disabled.svg);
}

/* Locked CheckBox */
.indicator-lock::indicator:checked,
.indicator-lock::indicator:checked:hover {
    image: url(theme:Light/locked.svg);
}

/* Visibility CheckBox */
.indicator-visibility::indicator:checked,
.indicator-visibility::indicator:checked:hover {
    image: url(theme:Light/visible.svg);
}

/* Mute CheckBox */
.indicator-mute::indicator:checked {
    image: url(theme:Light/mute.svg);
}

.indicator-mute::indicator:indeterminate {
    image: url(theme:Light/unassigned.svg);
}

.indicator-mute::indicator:unchecked {
    image: url(theme:Light/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:hover {
    image: url(theme:Light/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:focus {
    image: url(theme:Light/settings/audio.svg);
}

.indicator-mute::indicator:checked:hover {
    image: url(theme:Light/mute.svg);
}

.indicator-mute::indicator:checked:focus {
    image: url(theme:Light/mute.svg);
}

.indicator-mute::indicator:checked:disabled {
    image: url(theme:Light/mute.svg);
}

.indicator-mute::indicator:unchecked:disabled {
    image: url(theme:Light/settings/audio.svg);
}

/* Sources List Group Collapse Checkbox */
.indicator-expand::indicator:checked,
.indicator-expand::indicator:checked:hover {
    image: url(theme:Light/expand.svg);
}

.indicator-expand::indicator:unchecked,
.indicator-expand::indicator:unchecked:hover {
    image: url(theme:Light/collapse.svg);
}

/* Source Icons */
OBSBasic {
    qproperty-imageIcon: url(theme:Light/sources/image.svg);
    qproperty-colorIcon: url(theme:Light/sources/brush.svg);
    qproperty-slideshowIcon: url(theme:Light/sources/slideshow.svg);
    qproperty-audioInputIcon: url(theme:Light/sources/microphone.svg);
    qproperty-audioOutputIcon: url(theme:Light/settings/audio.svg);
    qproperty-desktopCapIcon: url(theme:Light/settings/video.svg);
    qproperty-windowCapIcon: url(theme:Light/sources/window.svg);
    qproperty-gameCapIcon: url(theme:Light/sources/gamepad.svg);
    qproperty-cameraIcon: url(theme:Light/sources/camera.svg);
    qproperty-textIcon: url(theme:Light/sources/text.svg);
    qproperty-mediaIcon: url(theme:Light/sources/media.svg);
    qproperty-browserIcon: url(theme:Light/sources/globe.svg);
    qproperty-groupIcon: url(theme:Light/sources/group.svg);
    qproperty-sceneIcon: url(theme:Light/sources/scene.svg);
    qproperty-defaultIcon: url(theme:Light/sources/default.svg);
    qproperty-audioProcessOutputIcon: url(theme:Light/sources/windowaudio.svg);
}

/* YouTube Integration */
OBSYoutubeActions {
    qproperty-thumbPlaceholder: url(theme:Light/sources/image.svg);
}

/* Calendar Widget */
QDateTimeEdit::down-arrow {
    image: url(theme:Light/down.svg);
}

/* Calendar Top Bar Buttons */
#qt_calendar_monthbutton::menu-indicator {
    image: url(theme:Light/down.svg);
}

QCalendarWidget #qt_calendar_prevmonth {
    qproperty-icon: url(theme:Light/left.svg);
}

QCalendarWidget #qt_calendar_nextmonth {
    qproperty-icon: url(theme:Light/right.svg);
}
    '';
    "obs-studio/themes/Catppuccin_Macchiato.ovt".text = ''
@OBSThemeMeta {
    name: 'Macchiato';
    id: 'com.obsproject.Catppuccin.Macchiato';
    extends: 'com.obsproject.Catppuccin';
    author: 'Xurdejl';
    dark: 'true';
}

@OBSThemeVars {
    --ctp_rosewater: #f4dbd6;
    --ctp_flamingo: #f0c6c6;
    --ctp_pink: #f5bde6;
    --ctp_mauve: #c6a0f6;
    --ctp_red: #ed8796;
    --ctp_maroon: #ee99a0;
    --ctp_peach: #f5a97f;
    --ctp_yellow: #eed49f;
    --ctp_green: #a6da95;
    --ctp_teal: #8bd5ca;
    --ctp_sky: #91d7e3;
    --ctp_sapphire: #7dc4e4;
    --ctp_blue: #8aadf4;
    --ctp_lavender: #b7bdf8;
    --ctp_text: #cad3f5;
    --ctp_subtext1: #b8c0e0;
    --ctp_subtext0: #a5adcb;
    --ctp_overlay2: #939ab7;
    --ctp_overlay1: #8087a2;
    --ctp_overlay0: #6e738d;
    --ctp_surface2: #5b6078;
    --ctp_surface1: #494d64;
    --ctp_surface0: #363a4f;
    --ctp_base: #24273a;
    --ctp_mantle: #1e2030;
    --ctp_crust: #181926;
    --ctp_selection_background: #3a3d53;
}

VolumeMeter {
    qproperty-foregroundNominalColor: #78c75d;
    qproperty-foregroundWarningColor: #ef7939;
    qproperty-foregroundErrorColor: #e3455d;
}

/* Icon Overrides */

.icon-plus {
    qproperty-icon: url(theme:Dark/plus.svg);
}

.icon-minus {
    qproperty-icon: url(theme:Dark/minus.svg);
}

.icon-trash {
    qproperty-icon: url(theme:Dark/trash.svg);
}

.icon-clear {
    qproperty-icon: url(theme:Dark/entry-clear.svg);
}

.icon-gear {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

.icon-dots-vert {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

.icon-refresh {
    qproperty-icon: url(theme:Dark/refresh.svg);
}

.icon-cogs {
    qproperty-icon: url(theme:Dark/cogs.svg);
}

.icon-touch {
    qproperty-icon: url(theme:Dark/interact.svg);
}

.icon-up {
    qproperty-icon: url(theme:Dark/up.svg);
}

.icon-down {
    qproperty-icon: url(theme:Dark/down.svg);
}

.icon-pause {
    qproperty-icon: url(theme:Dark/media-pause.svg);
}

.icon-filter {
    qproperty-icon: url(theme:Dark/filter.svg);
}

.icon-revert {
    qproperty-icon: url(theme:Dark/revert.svg);
}

.icon-save {
    qproperty-icon: url(theme:Dark/save.svg);
}

/* Media icons */

.icon-media-play {
    qproperty-icon: url(theme:Dark/media/media_play.svg);
}

.icon-media-pause {
    qproperty-icon: url(theme:Dark/media/media_pause.svg);
}

.icon-media-restart {
    qproperty-icon: url(theme:Dark/media/media_restart.svg);
}

.icon-media-stop {
    qproperty-icon: url(theme:Dark/media/media_stop.svg);
}

.icon-media-next {
    qproperty-icon: url(theme:Dark/media/media_next.svg);
}

.icon-media-prev {
    qproperty-icon: url(theme:Dark/media/media_previous.svg);
}

/* Context Menu */
QMenu::right-arrow {
    image: url(theme:Dark/expand.svg);
}

/* Dock Widget */
QDockWidget {
    titlebar-close-icon: url(theme:Dark/close.svg);
    titlebar-normal-icon: url(theme:Dark/popout.svg);
}

/* Source Context Bar */
QPushButton#sourcePropertiesButton {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

QPushButton#sourceFiltersButton {
    qproperty-icon: url(theme:Dark/filter.svg);
}

/* Scenes and Sources toolbar */
QToolBarExtension {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

/* ComboBox */
QComboBox::down-arrow,
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/collapse.svg);
}

QComboBox::down-arrow:editable,
QDateTimeEdit::down-arrow:editable {
    image: url(theme:Dark/collapse.svg);
}

/* Spinbox and doubleSpinbox */
QSpinBox::up-arrow,
QDoubleSpinBox::up-arrow {
    image: url(theme:Dark/up.svg);
}

QSpinBox::down-arrow,
QDoubleSpinBox::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Buttons */
QPushButton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

/* Settings Icons */
OBSBasicSettings {
    qproperty-generalIcon: url(theme:Dark/settings/general.svg);
    qproperty-appearanceIcon: url(theme:Dark/settings/appearance.svg);
    qproperty-streamIcon: url(theme:Dark/settings/stream.svg);
    qproperty-outputIcon: url(theme:Dark/settings/output.svg);
    qproperty-audioIcon: url(theme:Dark/settings/audio.svg);
    qproperty-videoIcon: url(theme:Dark/settings/video.svg);
    qproperty-hotkeysIcon: url(theme:Dark/settings/hotkeys.svg);
    qproperty-accessibilityIcon: url(theme:Dark/settings/accessibility.svg);
    qproperty-advancedIcon: url(theme:Dark/settings/advanced.svg);
}

/* Checkboxes */
QCheckBox::indicator:unchecked,
QGroupBox::indicator:unchecked {
    image: url(theme:Yami/checkbox_unchecked.svg);
}

QCheckBox::indicator:unchecked:hover,
QGroupBox::indicator:unchecked:hover {
    border: none;
    image: url(theme:Yami/checkbox_unchecked_focus.svg);
}

QCheckBox::indicator:checked,
QGroupBox::indicator:checked {
    image: url(theme:Yami/checkbox_checked.svg);
}

QCheckBox::indicator:checked:hover,
QGroupBox::indicator:checked:hover {
    image: url(theme:Yami/checkbox_checked_focus.svg);
}

QCheckBox::indicator:checked:disabled,
QGroupBox::indicator:checked:disabled {
    image: url(theme:Yami/checkbox_checked_disabled.svg);
}

/* Locked CheckBox */
.indicator-lock::indicator:checked,
.indicator-lock::indicator:checked:hover {
    image: url(theme:Dark/locked.svg);
}

/* Visibility CheckBox */
.indicator-visibility::indicator:checked,
.indicator-visibility::indicator:checked:hover {
    image: url(theme:Dark/visible.svg);
}

/* Mute CheckBox */
.indicator-mute::indicator:checked {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:indeterminate {
    image: url(theme:Dark/unassigned.svg);
}

.indicator-mute::indicator:unchecked {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:hover {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:focus {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:checked:hover {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:focus {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:disabled {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:unchecked:disabled {
    image: url(theme:Dark/settings/audio.svg);
}

/* Sources List Group Collapse Checkbox */
.indicator-expand::indicator:checked,
.indicator-expand::indicator:checked:hover {
    image: url(theme:Dark/expand.svg);
}

.indicator-expand::indicator:unchecked,
.indicator-expand::indicator:unchecked:hover {
    image: url(theme:Dark/collapse.svg);
}

/* Source Icons */
OBSBasic {
    qproperty-imageIcon: url(theme:Dark/sources/image.svg);
    qproperty-colorIcon: url(theme:Dark/sources/brush.svg);
    qproperty-slideshowIcon: url(theme:Dark/sources/slideshow.svg);
    qproperty-audioInputIcon: url(theme:Dark/sources/microphone.svg);
    qproperty-audioOutputIcon: url(theme:Dark/settings/audio.svg);
    qproperty-desktopCapIcon: url(theme:Dark/settings/video.svg);
    qproperty-windowCapIcon: url(theme:Dark/sources/window.svg);
    qproperty-gameCapIcon: url(theme:Dark/sources/gamepad.svg);
    qproperty-cameraIcon: url(theme:Dark/sources/camera.svg);
    qproperty-textIcon: url(theme:Dark/sources/text.svg);
    qproperty-mediaIcon: url(theme:Dark/sources/media.svg);
    qproperty-browserIcon: url(theme:Dark/sources/globe.svg);
    qproperty-groupIcon: url(theme:Dark/sources/group.svg);
    qproperty-sceneIcon: url(theme:Dark/sources/scene.svg);
    qproperty-defaultIcon: url(theme:Dark/sources/default.svg);
    qproperty-audioProcessOutputIcon: url(theme:Dark/sources/windowaudio.svg);
}

/* YouTube Integration */
OBSYoutubeActions {
    qproperty-thumbPlaceholder: url(theme:Dark/sources/image.svg);
}

/* Calendar Widget */
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Calendar Top Bar Buttons */
#qt_calendar_monthbutton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

QCalendarWidget #qt_calendar_prevmonth {
    qproperty-icon: url(theme:Dark/left.svg);
}

QCalendarWidget #qt_calendar_nextmonth {
    qproperty-icon: url(theme:Dark/right.svg);
}
    '';
    "obs-studio/themes/Catppuccin_Mocha.ovt".text = ''
@OBSThemeMeta {
    name: 'Mocha';
    id: 'com.obsproject.Catppuccin.Mocha';
    extends: 'com.obsproject.Catppuccin';
    author: 'Xurdejl';
    dark: 'true';
}

@OBSThemeVars {
    --ctp_rosewater: #f5e0dc;
    --ctp_flamingo: #f2cdcd;
    --ctp_pink: #f5c2e7;
    --ctp_mauve: #cba6f7;
    --ctp_red: #f38ba8;
    --ctp_maroon: #eba0ac;
    --ctp_peach: #fab387;
    --ctp_yellow: #f9e2af;
    --ctp_green: #a6e3a1;
    --ctp_teal: #94e2d5;
    --ctp_sky: #89dceb;
    --ctp_sapphire: #74c7ec;
    --ctp_blue: #89b4fa;
    --ctp_lavender: #b4befe;
    --ctp_text: #cdd6f4;
    --ctp_subtext1: #bac2de;
    --ctp_subtext0: #a6adc8;
    --ctp_overlay2: #9399b2;
    --ctp_overlay1: #7f849c;
    --ctp_overlay0: #6c7086;
    --ctp_surface2: #585b70;
    --ctp_surface1: #45475a;
    --ctp_surface0: #313244;
    --ctp_base: #1e1e2e;
    --ctp_mantle: #181825;
    --ctp_crust: #11111b;
    --ctp_selection_background: #353649;
}

VolumeMeter {
    qproperty-foregroundNominalColor: #6fd266;
    qproperty-foregroundWarningColor: #f7853f;
    qproperty-foregroundErrorColor: #ec4675;
}

/* Icon Overrides */

.icon-plus {
    qproperty-icon: url(theme:Dark/plus.svg);
}

.icon-minus {
    qproperty-icon: url(theme:Dark/minus.svg);
}

.icon-trash {
    qproperty-icon: url(theme:Dark/trash.svg);
}

.icon-clear {
    qproperty-icon: url(theme:Dark/entry-clear.svg);
}

.icon-gear {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

.icon-dots-vert {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

.icon-refresh {
    qproperty-icon: url(theme:Dark/refresh.svg);
}

.icon-cogs {
    qproperty-icon: url(theme:Dark/cogs.svg);
}

.icon-touch {
    qproperty-icon: url(theme:Dark/interact.svg);
}

.icon-up {
    qproperty-icon: url(theme:Dark/up.svg);
}

.icon-down {
    qproperty-icon: url(theme:Dark/down.svg);
}

.icon-pause {
    qproperty-icon: url(theme:Dark/media-pause.svg);
}

.icon-filter {
    qproperty-icon: url(theme:Dark/filter.svg);
}

.icon-revert {
    qproperty-icon: url(theme:Dark/revert.svg);
}

.icon-save {
    qproperty-icon: url(theme:Dark/save.svg);
}

/* Media icons */

.icon-media-play {
    qproperty-icon: url(theme:Dark/media/media_play.svg);
}

.icon-media-pause {
    qproperty-icon: url(theme:Dark/media/media_pause.svg);
}

.icon-media-restart {
    qproperty-icon: url(theme:Dark/media/media_restart.svg);
}

.icon-media-stop {
    qproperty-icon: url(theme:Dark/media/media_stop.svg);
}

.icon-media-next {
    qproperty-icon: url(theme:Dark/media/media_next.svg);
}

.icon-media-prev {
    qproperty-icon: url(theme:Dark/media/media_previous.svg);
}

/* Context Menu */
QMenu::right-arrow {
    image: url(theme:Dark/expand.svg);
}

/* Dock Widget */
QDockWidget {
    titlebar-close-icon: url(theme:Dark/close.svg);
    titlebar-normal-icon: url(theme:Dark/popout.svg);
}

/* Source Context Bar */
QPushButton#sourcePropertiesButton {
    qproperty-icon: url(theme:Dark/settings/general.svg);
}

QPushButton#sourceFiltersButton {
    qproperty-icon: url(theme:Dark/filter.svg);
}

/* Scenes and Sources toolbar */
QToolBarExtension {
    qproperty-icon: url(theme:Dark/dots-vert.svg);
}

/* ComboBox */
QComboBox::down-arrow,
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/collapse.svg);
}

QComboBox::down-arrow:editable,
QDateTimeEdit::down-arrow:editable {
    image: url(theme:Dark/collapse.svg);
}

/* Spinbox and doubleSpinbox */
QSpinBox::up-arrow,
QDoubleSpinBox::up-arrow {
    image: url(theme:Dark/up.svg);
}

QSpinBox::down-arrow,
QDoubleSpinBox::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Buttons */
QPushButton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

/* Settings Icons */
OBSBasicSettings {
    qproperty-generalIcon: url(theme:Dark/settings/general.svg);
    qproperty-appearanceIcon: url(theme:Dark/settings/appearance.svg);
    qproperty-streamIcon: url(theme:Dark/settings/stream.svg);
    qproperty-outputIcon: url(theme:Dark/settings/output.svg);
    qproperty-audioIcon: url(theme:Dark/settings/audio.svg);
    qproperty-videoIcon: url(theme:Dark/settings/video.svg);
    qproperty-hotkeysIcon: url(theme:Dark/settings/hotkeys.svg);
    qproperty-accessibilityIcon: url(theme:Dark/settings/accessibility.svg);
    qproperty-advancedIcon: url(theme:Dark/settings/advanced.svg);
}

/* Checkboxes */
QCheckBox::indicator:unchecked,
QGroupBox::indicator:unchecked {
    image: url(theme:Yami/checkbox_unchecked.svg);
}

QCheckBox::indicator:unchecked:hover,
QGroupBox::indicator:unchecked:hover {
    border: none;
    image: url(theme:Yami/checkbox_unchecked_focus.svg);
}

QCheckBox::indicator:checked,
QGroupBox::indicator:checked {
    image: url(theme:Yami/checkbox_checked.svg);
}

QCheckBox::indicator:checked:hover,
QGroupBox::indicator:checked:hover {
    image: url(theme:Yami/checkbox_checked_focus.svg);
}

QCheckBox::indicator:checked:disabled,
QGroupBox::indicator:checked:disabled {
    image: url(theme:Yami/checkbox_checked_disabled.svg);
}

/* Locked CheckBox */
.indicator-lock::indicator:checked,
.indicator-lock::indicator:checked:hover {
    image: url(theme:Dark/locked.svg);
}

/* Visibility CheckBox */
.indicator-visibility::indicator:checked,
.indicator-visibility::indicator:checked:hover {
    image: url(theme:Dark/visible.svg);
}

/* Mute CheckBox */
.indicator-mute::indicator:checked {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:indeterminate {
    image: url(theme:Dark/unassigned.svg);
}

.indicator-mute::indicator:unchecked {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:hover {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:unchecked:focus {
    image: url(theme:Dark/settings/audio.svg);
}

.indicator-mute::indicator:checked:hover {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:focus {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:checked:disabled {
    image: url(theme:Dark/mute.svg);
}

.indicator-mute::indicator:unchecked:disabled {
    image: url(theme:Dark/settings/audio.svg);
}

/* Sources List Group Collapse Checkbox */
.indicator-expand::indicator:checked,
.indicator-expand::indicator:checked:hover {
    image: url(theme:Dark/expand.svg);
}

.indicator-expand::indicator:unchecked,
.indicator-expand::indicator:unchecked:hover {
    image: url(theme:Dark/collapse.svg);
}

/* Source Icons */
OBSBasic {
    qproperty-imageIcon: url(theme:Dark/sources/image.svg);
    qproperty-colorIcon: url(theme:Dark/sources/brush.svg);
    qproperty-slideshowIcon: url(theme:Dark/sources/slideshow.svg);
    qproperty-audioInputIcon: url(theme:Dark/sources/microphone.svg);
    qproperty-audioOutputIcon: url(theme:Dark/settings/audio.svg);
    qproperty-desktopCapIcon: url(theme:Dark/settings/video.svg);
    qproperty-windowCapIcon: url(theme:Dark/sources/window.svg);
    qproperty-gameCapIcon: url(theme:Dark/sources/gamepad.svg);
    qproperty-cameraIcon: url(theme:Dark/sources/camera.svg);
    qproperty-textIcon: url(theme:Dark/sources/text.svg);
    qproperty-mediaIcon: url(theme:Dark/sources/media.svg);
    qproperty-browserIcon: url(theme:Dark/sources/globe.svg);
    qproperty-groupIcon: url(theme:Dark/sources/group.svg);
    qproperty-sceneIcon: url(theme:Dark/sources/scene.svg);
    qproperty-defaultIcon: url(theme:Dark/sources/default.svg);
    qproperty-audioProcessOutputIcon: url(theme:Dark/sources/windowaudio.svg);
}

/* YouTube Integration */
OBSYoutubeActions {
    qproperty-thumbPlaceholder: url(theme:Dark/sources/image.svg);
}

/* Calendar Widget */
QDateTimeEdit::down-arrow {
    image: url(theme:Dark/down.svg);
}

/* Calendar Top Bar Buttons */
#qt_calendar_monthbutton::menu-indicator {
    image: url(theme:Dark/down.svg);
}

QCalendarWidget #qt_calendar_prevmonth {
    qproperty-icon: url(theme:Dark/left.svg);
}

QCalendarWidget #qt_calendar_nextmonth {
    qproperty-icon: url(theme:Dark/right.svg);
}
    '';
  };

  # OBS writes to its config files at runtime (scenes, prefs), so these are
  # copied once on first deploy rather than symlinked from the store.
  # Guard: only seeds if the Webcam_On profile doesn't exist yet.
  home.activation.obsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    let
      globalIni = pkgs.writeText "obs-global.ini" ''
        [General]
        Pre31Migrated=true
        MaxLogs=10
        InfoIncrement=-1
        ProcessPriority=Normal
        BrowserHWAccel=true

        [Video]
        Renderer=OpenGL

        [PropertiesWindow]
        cx=1600
        cy=1200
      '';

      basicIni = pkgs.writeText "obs-basic-webcam-on.ini" ''
        [General]
        Name=Webcam On

        [Output]
        Mode=Advanced
        FilenameFormatting=%CCYY-%MM-%DD %hh-%mm-%ss
        DelayEnable=false
        DelaySec=20
        DelayPreserve=true
        Reconnect=true
        RetryDelay=1
        MaxRetries=25
        BindIP=default
        IPFamily=IPv4+IPv6
        NewSocketLoopEnable=false
        LowLatencyEnable=false

        [Stream1]
        IgnoreRecommended=false
        EnableMultitrackVideo=false
        MultitrackVideoMaximumAggregateBitrateAuto=true
        MultitrackVideoMaximumVideoTracksAuto=true

        [SimpleOutput]
        FilePath=/home/xrs444
        RecFormat2=mkv
        VBitrate=2500
        ABitrate=192
        UseAdvanced=false
        Preset=veryfast
        NVENCPreset2=p5
        RecQuality=Stream
        RecRB=false
        RecRBTime=20
        RecRBSize=512
        RecRBPrefix=Replay
        StreamAudioEncoder=aac
        RecAudioEncoder=aac
        RecTracks=1
        StreamEncoder=nvenc
        RecEncoder=nvenc

        [AdvOut]
        ApplyServiceSettings=true
        UseRescale=false
        TrackIndex=1
        VodTrackIndex=2
        Encoder=jim_nvenc
        RecType=Standard
        RecFilePath=/home/xrs444
        RecFormat2=mkv
        RecUseRescale=false
        RecTracks=1
        RecEncoder=none
        FLVTrack=1
        StreamMultiTrackAudioMixes=1
        FFOutputToFile=true
        FFFilePath=/home/xrs444
        FFVBitrate=2500
        FFVGOPSize=250
        FFUseRescale=false
        FFIgnoreCompat=false
        FFABitrate=160
        FFAudioMixes=1
        Track1Bitrate=192
        Track2Bitrate=192
        Track3Bitrate=192
        Track4Bitrate=192
        Track5Bitrate=192
        Track6Bitrate=192
        RecSplitFileTime=15
        RecSplitFileSize=2048
        RecRB=false
        RecRBTime=20
        RecRBSize=512
        AudioEncoder=libfdk_aac
        RecAudioEncoder=libfdk_aac
        RescaleRes=960x720
        RecRescaleRes=960x720
        RecSplitFileType=Time
        FFFormat=
        FFFormatMimeType=
        FFRescaleRes=960x720
        FFVEncoderId=0
        FFVEncoder=
        FFAEncoderId=0
        FFAEncoder=
        FFExtension=mp4

        [Video]
        BaseCX=1920
        BaseCY=1080
        OutputCX=1920
        OutputCY=1080
        FPSType=0
        FPSCommon=30
        FPSInt=30
        FPSNum=30
        FPSDen=1
        ScaleType=bicubic
        ColorFormat=NV12
        ColorSpace=709
        ColorRange=Partial
        SdrWhiteLevel=300
        HdrNominalPeakLevel=1000

        [Audio]
        MonitoringDeviceId=combined-obs
        MonitoringDeviceName=Pebble + Schiit + SPDIF Out
        SampleRate=48000
        ChannelSetup=Stereo
        MeterDecayRate=23.53
        PeakMeterType=1

        [Panels]
        CookieId=DD38C8C7393B3F56

        [OBSWebSocket]
        ServerEnabled=true
        ServerPort=4455
        AuthRequired=true
        AlertsEnabled=false
      '';

      serviceJson = pkgs.writeText "obs-service.json" ''
        {"type":"rtmp_custom","settings":{"server":"","use_auth":false,"bwtest":false,"key":""}}
      '';

      streamEncoderJson = pkgs.writeText "obs-streamEncoder.json" "{}";

      userIni = pkgs.writeText "obs-user.ini" ''
[General]
Pre19Defaults=false
Pre21Defaults=false
Pre23Defaults=false
Pre24.1Defaults=false
ConfirmOnExit=true
HotkeyFocusType=NeverDisableHotkeys
FirstRun=true

[BasicWindow]
PreviewEnabled=true
PreviewProgramMode=false
SceneDuplicationMode=true
SwapScenesMode=true
SnappingEnabled=true
ScreenSnapping=true
SourceSnapping=true
CenterSnapping=false
SnapDistance=0.0
SpacingHelpersEnabled=true
RecordWhenStreaming=false
KeepRecordingWhenStreamStops=false
SysTrayEnabled=true
SysTrayWhenStarted=false
SaveProjectors=true
ShowTransitions=true
ShowListboxToolbars=true
ShowStatusBar=true
ShowSourceIcons=true
ShowContextToolbars=true
StudioModeLabels=true
VerticalVolControl=true
MultiviewMouseSwitch=true
MultiviewDrawNames=true
MultiviewDrawAreas=true
MediaControlsCountdownTimer=true
geometry=AdnQywADAAAAAAAAAAAAAAAABj8AAASvAAABPwAAABkAAAY+AAAD2AAAAAACBAAABkAAAAAAAAAAAAAABj8AAASv
DockState=AAAA/wAAAAD9AAAAAgAAAAEAAABTAAADK/wCAAAAAvsAAAAgAEEAdQBkAGkAbwBNAG8AbgBpAHQAbwByAEQAbwBjAGsBAAAAFwAAAysAAABpAP////sAAAAiAGEAZAB2AHMAcwAtAHMAdABhAHQAdQBzAC0AZABvAGMAawIAAAXcAAABPgAAAGQAAAAeAAAAAwAABkAAAAFI/AEAAAAG+wAAABQAcwBjAGUAbgBlAHMARABvAGMAawEAAAAAAAABDQAAAJgA////+wAAABYAcwBvAHUAcgBjAGUAcwBEAG8AYwBrAQAAAREAAAEIAAAAmAD////7AAAAEgBtAGkAeABlAHIARABvAGMAawEAAAIdAAABggAAASMA////+wAAAB4AdAByAGEAbgBzAGkAdABpAG8AbgBzAEQAbwBjAGsBAAADowAAAS4AAACkAP////sAAAAYAGMAbwBuAHQAcgBvAGwAcwBEAG8AYwBrAQAABNUAAAFrAAAAzgD////7AAAAEgBzAHQAYQB0AHMARABvAGMAawAAAAOQAAACsAAAArEA////AAAF6QAAAysAAAAEAAAABAAAAAgAAAAI/AAAAAA=
AlwaysOnTop=false
EditPropertiesMode=false
DocksLocked=false
SideDocks=false
WarnBeforeStartingStream=false
WarnBeforeStoppingStream=false
WarnBeforeStoppingRecord=false
HideProjectorCursor=true
ProjectorAlwaysOnTop=true
CloseExistingProjectors=true
TransitionOnDoubleClick=true
VerticalVolumeControl=true
MixerShowInactive=false
MixerKeepInactiveLast=false
MixerShowHidden=false
MixerKeepHiddenLast=false

[Basic]
Profile=Webcam On
ProfileDir=Webcam_On
SceneCollection=default
SceneCollectionFile=default.json
ConfigOnNewProfile=true

[ScriptLogWindow]
geometry=AdnQywADAAAAAAFBAAABVwAAA5gAAALmAAABQQAAAVcAAAOYAAAC5gAAAAAAAAAABkAAAAFBAAABVwAAA5gAAALm

[Accessibility]
SelectRed=255
SelectGreen=65280
SelectBlue=16744192
MixerGreen=2522918
MixerYellow=2523007
MixerRed=2500223
MixerGreenActive=5046092
MixerYellowActive=5046271
MixerRedActive=5000447

[Appearance]
FontScale=10
Density=-4
Theme=com.obsproject.Catppuccin.Mocha
      '';

      # Scene collection from the flatpak import — paths are patched after copy.
      scenesJson = pkgs.writeText "obs-scenes.json" ''
{
    "name": "default",
    "DesktopAudioDevice1": {
        "prev_ver": 536936450,
        "name": "Desktop Audio",
        "uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
        "id": "pulse_output_capture",
        "versioned_id": "pulse_output_capture",
        "settings": {
            "device_id": "default"
        },
        "mixers": 255,
        "sync": 0,
        "flags": 0,
        "volume": 1.0,
        "balance": 0.5,
        "enabled": true,
        "muted": true,
        "push-to-mute": false,
        "push-to-mute-delay": 0,
        "push-to-talk": false,
        "push-to-talk-delay": 0,
        "hotkeys": {
            "libobs.mute": [],
            "libobs.unmute": [],
            "libobs.push-to-mute": [],
            "libobs.push-to-talk": []
        },
        "deinterlace_mode": 0,
        "deinterlace_field_order": 0,
        "monitoring_type": 0,
        "private_settings": {}
    },
    "sources": [
        {
            "prev_ver": 536936450,
            "name": "Me",
            "uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
            "id": "v4l2_input",
            "versioned_id": "v4l2_input",
            "settings": {
                "device_id": "/dev/video3",
                "input": 0,
                "pixelformat": 1196444237,
                "resolution": 5497558139600,
                "framerate": -1
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {},
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "BackgroundRemoval",
                    "uuid": "afb65e97-3c0f-4760-ba47-2b3a62e756be",
                    "id": "background_removal",
                    "versioned_id": "background_removal",
                    "settings": {
                        "advanced": true,
                        "enable_threshold": false,
                        "threshold": 0.14999999999999999,
                        "feather": 0.14999999999999999,
                        "model_select": "models/rvm_mobilenetv3_fp32.onnx",
                        "blur_background": 0,
                        "numThreads": 3,
                        "image_similarity_threshold": 50.0
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                },
                {
                    "prev_ver": 536936450,
                    "name": "ChromaKey",
                    "uuid": "fbcbe5ee-3bfc-4658-96e4-f7446975a5cd",
                    "id": "chroma_key_filter",
                    "versioned_id": "chroma_key_filter_v2",
                    "settings": {},
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "Desk",
            "uuid": "bff35b60-db6e-49f2-9717-dca367b26fcd",
            "id": "v4l2_input",
            "versioned_id": "v4l2_input",
            "settings": {
                "device_id": "/dev/video1",
                "input": 0,
                "pixelformat": 1196444237,
                "resolution": 8246337209400
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {},
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "GStreamer Filter (Video)",
                    "uuid": "a0ffd574-163e-472e-a0b0-e2681118dcc2",
                    "id": "gstreamer-filter-video",
                    "versioned_id": "gstreamer-filter-video",
                    "settings": {
                        "pipeline": "videoflip video-direction=horiz\nvideoflip video-direction=verti"
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "DefaultBackground",
            "uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
            "id": "image_source",
            "versioned_id": "image_source",
            "settings": {
                "file": "/var/home/xrs444/Documents/OBS/space1080.webp"
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {},
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "barsimage",
            "uuid": "871367d7-c449-4c1b-bbca-36c59576ab78",
            "id": "image_source",
            "versioned_id": "image_source",
            "settings": {
                "file": "/var/home/xrs444/Documents/OBS/SMPTE_Color_Bars_16x9.png"
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {},
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "BackgroundVideoInsert",
            "uuid": "04483948-d0ad-4fa1-b2c7-56724c21a8b6",
            "id": "ffmpeg_source",
            "versioned_id": "ffmpeg_source",
            "settings": {
                "hw_decode": true,
                "close_when_inactive": true,
                "local_file": "/var/home/xrs444/Videos/OBSBackgroundVideo.mp4",
                "looping": true
            },
            "mixers": 255,
            "sync": 0,
            "flags": 0,
            "volume": 0.1875331699848175,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "libobs.mute": [],
                "libobs.unmute": [],
                "libobs.push-to-mute": [],
                "libobs.push-to-talk": [],
                "MediaSource.Restart": [],
                "MediaSource.Play": [],
                "MediaSource.Pause": [],
                "MediaSource.Stop": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 2,
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "AudioInsertFile",
            "uuid": "15b7a819-c317-498a-9698-76c571696cf1",
            "id": "ffmpeg_source",
            "versioned_id": "ffmpeg_source",
            "settings": {
                "hw_decode": true,
                "close_when_inactive": true,
                "local_file": "/var/home/xrs444/OBS/Audio/OBSSoundInsert.mp3",
                "looping": false,
                "restart_on_activate": false
            },
            "mixers": 255,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "libobs.mute": [],
                "libobs.unmute": [],
                "libobs.push-to-mute": [],
                "libobs.push-to-talk": [],
                "MediaSource.Restart": [],
                "MediaSource.Play": [],
                "MediaSource.Pause": [],
                "MediaSource.Stop": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 2,
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "Cam",
            "uuid": "614a7634-6285-4244-b9fc-661032d8c455",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 7,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 4,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 5.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -0.99074071645736694
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1915.0,
                            "y": 1083.0
                        },
                        "pos_rel": {
                            "x": 1.7685185670852661,
                            "y": 1.0055556297302246
                        },
                        "scale": {
                            "x": 1.49609375,
                            "y": 1.4958332777023315
                        },
                        "scale_rel": {
                            "x": 1.49609375,
                            "y": 1.4958332777023315
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 7,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": [],
                "libobs.show_scene_item.4": [],
                "libobs.hide_scene_item.4": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.7": [],
                "libobs.hide_scene_item.7": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "DeskCam",
            "uuid": "88608670-b701-48ed-be84-93e35e55f747",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 3,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desk",
                        "source_uuid": "bff35b60-db6e-49f2-9717-dca367b26fcd",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "pos_rel": {
                            "x": 1.7777777910232544,
                            "y": 1.0000002384185791
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "DeskCamOverlay",
            "uuid": "512e918a-ddb9-491a-b08a-e94adf0b0b7e",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 4,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 4,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desk",
                        "source_uuid": "bff35b60-db6e-49f2-9717-dca367b26fcd",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "pos_rel": {
                            "x": 1.7777777910232544,
                            "y": 1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 757.0,
                            "y": 1080.0
                        },
                        "pos_rel": {
                            "x": -0.37592592835426331,
                            "y": 1.0
                        },
                        "scale": {
                            "x": 0.59140622615814209,
                            "y": 0.59166663885116577
                        },
                        "scale_rel": {
                            "x": 0.59140622615814209,
                            "y": 0.59166663885116577
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.4": [],
                "libobs.hide_scene_item.4": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "bars",
            "uuid": "fb76a21d-2984-4c13-8cae-d655af2876b5",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 3,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "barsimage",
                        "source_uuid": "871367d7-c449-4c1b-bbca-36c59576ab78",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": -1.0,
                            "y": 3.0
                        },
                        "pos_rel": {
                            "x": -1.7796295881271362,
                            "y": -0.99444442987442017
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "BackgroundVideo",
            "uuid": "05976be1-b136-4556-931f-3ed983a63119",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 3,
                "custom_size": false,
                "items": [
                    {
                        "name": "BackgroundVideoInsert",
                        "source_uuid": "04483948-d0ad-4fa1-b2c7-56724c21a8b6",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 10.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7592592239379883,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 3.0031447410583496,
                            "y": 3.0027778148651123
                        },
                        "scale_rel": {
                            "x": 3.0031447410583496,
                            "y": 3.0027778148651123
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "pos_rel": {
                            "x": 1.7777777910232544,
                            "y": 1.0
                        },
                        "scale": {
                            "x": 1.4937499761581421,
                            "y": 1.4944444894790649
                        },
                        "scale_rel": {
                            "x": 1.4937499761581421,
                            "y": 1.4944444894790649
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        },
        {
            "prev_ver": 536936450,
            "name": "matrix",
            "uuid": "95600b46-a87d-4755-959a-4e313f6cae1a",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 5,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": false,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1921.0,
                            "y": 1081.0
                        },
                        "pos_rel": {
                            "x": 1.7796295881271362,
                            "y": 1.0018517971038818
                        },
                        "scale": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "scale_rel": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "matrix",
                    "uuid": "4f0aa3da-1b63-40aa-aebb-c41a5a703e6e",
                    "id": "obs_retro_effects_filter",
                    "versioned_id": "obs_retro_effects_filter",
                    "settings": {
                        "filter_type": 9,
                        "matrix_rain_scale": 0.28000000000000003,
                        "matrix_rain_noise_shift": 19.399999999999999,
                        "matrix_rain_colorize": false,
                        "matrix_active_rain_brightness": 0.38,
                        "matrix_speed_factor": 1.24
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "glitch",
            "uuid": "de0b3ddf-eb7d-4bef-b507-842e83388b58",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 5,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1921.0,
                            "y": 1081.0
                        },
                        "pos_rel": {
                            "x": 1.7796295881271362,
                            "y": 1.0018517971038818
                        },
                        "scale": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "scale_rel": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "matrix",
                    "uuid": "9db1f499-ac1d-49a5-9acf-c78cd35cad34",
                    "id": "obs_retro_effects_filter",
                    "versioned_id": "obs_retro_effects_filter",
                    "settings": {
                        "filter_type": 14
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "crt",
            "uuid": "4d150856-8447-474d-b065-34cf938a7bf5",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 5,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1921.0,
                            "y": 1081.0
                        },
                        "pos_rel": {
                            "x": 1.7796295881271362,
                            "y": 1.0018517971038818
                        },
                        "scale": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "scale_rel": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "matrix",
                    "uuid": "b6b890b1-34a0-482c-9aae-64a2a2193bc4",
                    "id": "obs_retro_effects_filter",
                    "versioned_id": "obs_retro_effects_filter",
                    "settings": {
                        "filter_type": 6
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "codec",
            "uuid": "cbf4bb60-6ce8-4953-b73c-334e789b5652",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 5,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1921.0,
                            "y": 1081.0
                        },
                        "pos_rel": {
                            "x": 1.7796295881271362,
                            "y": 1.0018517971038818
                        },
                        "scale": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "scale_rel": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "matrix",
                    "uuid": "28d21889-2d05-423b-b1a4-2ff76a87a75f",
                    "id": "obs_retro_effects_filter",
                    "versioned_id": "obs_retro_effects_filter",
                    "settings": {
                        "filter_type": 10,
                        "codec_px_scale": 11.25,
                        "codec_colors_per_channel": 85,
                        "codec_quality": 0.53000000000000003
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        },
        {
            "prev_ver": 536936450,
            "name": "ntsc",
            "uuid": "e5d9f9ed-8121-4bdf-b4d4-f87255b1d1c9",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 5,
                "custom_size": false,
                "items": [
                    {
                        "name": "AudioInsertFile",
                        "source_uuid": "15b7a819-c317-498a-9698-76c571696cf1",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 1,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "DefaultBackground",
                        "source_uuid": "bb0d005f-c713-464a-a6d8-0e6f4ca56934",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 150.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.5,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "scale_rel": {
                            "x": 0.99938273429870605,
                            "y": 0.99907410144805908
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Me",
                        "source_uuid": "afa72e82-dfa5-4149-a209-b3160eec60ef",
                        "visible": true,
                        "locked": false,
                        "rot": 180.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 1921.0,
                            "y": 1081.0
                        },
                        "pos_rel": {
                            "x": 1.7796295881271362,
                            "y": 1.0018517971038818
                        },
                        "scale": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "scale_rel": {
                            "x": 1.5007812976837158,
                            "y": 1.5013889074325562
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "Desktop Audio",
                        "source_uuid": "c6afcdd2-c70c-4cfd-abfc-ffec942e01f7",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "scale_ref": {
                            "x": 1920.0,
                            "y": 1080.0
                        },
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 5,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "pos_rel": {
                            "x": -1.7777777910232544,
                            "y": -1.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "scale_rel": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "bounds_rel": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 0
                        },
                        "hide_transition": {
                            "duration": 0
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.1": [],
                "libobs.hide_scene_item.1": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": [],
                "libobs.show_scene_item.5": [],
                "libobs.hide_scene_item.5": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {},
            "filters": [
                {
                    "prev_ver": 536936450,
                    "name": "matrix",
                    "uuid": "f64d6fde-9a0c-4c75-9323-ee8b9b998a49",
                    "id": "obs_retro_effects_filter",
                    "versioned_id": "obs_retro_effects_filter",
                    "settings": {
                        "filter_type": 7,
                        "ntsc_luma_noise": 49.299999999999997,
                        "ntsc_luma_band_size": 70.099999999999994,
                        "ntsc_luma_band_strength": 137.59999999999999,
                        "ntsc_luma_band_count": 1,
                        "ntsc_chroma_bleed_size": 17.0,
                        "ntsc_chroma_bleed_strength": 40.0,
                        "ntsc_chroma_bleed_steps": 14,
                        "ntsc_brightness": 100.09999999999999
                    },
                    "mixers": 0,
                    "sync": 0,
                    "flags": 0,
                    "volume": 1.0,
                    "balance": 0.5,
                    "enabled": true,
                    "muted": false,
                    "push-to-mute": false,
                    "push-to-mute-delay": 0,
                    "push-to-talk": false,
                    "push-to-talk-delay": 0,
                    "hotkeys": {},
                    "deinterlace_mode": 0,
                    "deinterlace_field_order": 0,
                    "monitoring_type": 0,
                    "private_settings": {}
                }
            ]
        }
    ],
    "groups": [],
    "scene_order": [
        {
            "name": "bars"
        },
        {
            "name": "Cam"
        },
        {
            "name": "matrix"
        },
        {
            "name": "glitch"
        },
        {
            "name": "crt"
        },
        {
            "name": "codec"
        },
        {
            "name": "ntsc"
        },
        {
            "name": "DeskCam"
        },
        {
            "name": "DeskCamOverlay"
        },
        {
            "name": "BackgroundVideo"
        }
    ],
    "current_scene": "DeskCamOverlay",
    "current_program_scene": "DeskCamOverlay",
    "canvases": [],
    "current_transition": "Fade",
    "transition_duration": 300,
    "transitions": [
        {
            "name": "Slide",
            "id": "slide_transition",
            "settings": {
                "direction": "left"
            }
        }
    ],
    "quick_transitions": [
        {
            "name": "Cut",
            "duration": 300,
            "hotkeys": [],
            "id": 1,
            "fade_to_black": false
        },
        {
            "name": "Fade",
            "duration": 300,
            "hotkeys": [],
            "id": 2,
            "fade_to_black": false
        },
        {
            "name": "Fade",
            "duration": 300,
            "hotkeys": [],
            "id": 3,
            "fade_to_black": true
        }
    ],
    "saved_projectors": [
        {
            "monitor": 1,
            "type": 2,
            "geometry": "AdnQywADAAAAAAAAAAAG6gAAB38AAAshAAAAAAAABuoAAAd/AAALIQAAAAECBAAAB4AAAAAAAAAG6gAAB38AAAsh",
            "alwaysOnTopOverridden": false
        }
    ],
    "preview_locked": false,
    "scaling_enabled": true,
    "scaling_level": -8,
    "scaling_off_x": -33.735015869140625,
    "scaling_off_y": 29.049594879150391,
    "virtual-camera": {
        "type2": 3
    },
    "modules": {
        "scripts-tool": [],
        "output-timer": {
            "streamTimerHours": 0,
            "streamTimerMinutes": 0,
            "streamTimerSeconds": 30,
            "recordTimerHours": 0,
            "recordTimerMinutes": 0,
            "recordTimerSeconds": 30,
            "autoStartStreamTimer": false,
            "autoStartRecordTimer": false,
            "pauseRecordTimer": true
        },
        "transition-table": {
            "transitions": [],
            "dialog_width": 1600,
            "dialog_height": 1200,
            "enable_hotkey": [],
            "disable_hotkey": []
        },
        "advanced-scene-switcher": {
            "sceneGroups": [],
            "macros": [],
            "macroSettings": {
                "highlightExecuted": false,
                "highlightConditions": false,
                "highlightActions": false,
                "newMacroCheckInParallel": false,
                "newMacroRegisterHotkey": false,
                "newMacroUseShortCircuitEvaluation": false,
                "saveSettingsOnMacroChange": true
            },
            "switches": [],
            "ignoreWindows": [],
            "screenRegion": [],
            "pauseEntries": [],
            "sceneRoundTrip": [],
            "sceneTransitions": [],
            "defaultTransitions": [],
            "defTransitionDelay": 0,
            "ignoreIdleWindows": [],
            "idleTargetType": 0,
            "idleSceneName": "",
            "idleTransitionName": "",
            "idleEnable": false,
            "idleTime": 60,
            "executableSwitches": [],
            "randomSwitches": [],
            "fileSwitches": [],
            "readEnabled": false,
            "readPath": "",
            "writeEnabled": false,
            "writePath": "",
            "mediaSwitches": [],
            "timeSwitches": [],
            "audioSwitches": [],
            "audioFallbackTargetType": 0,
            "audioFallbackScene": "",
            "audioFallbackTransition": "",
            "audioFallbackEnable": false,
            "audioFallbackDuration": {
                "value": {
                    "value": 0.0,
                    "type": 0
                },
                "unit": 0,
                "version": 1
            },
            "videoSwitches": [],
            "interval": 300,
            "noMatchScene": {
                "sceneSelection": {
                    "type": 0,
                    "name": "",
                    "canvasSelection": "Main"
                }
            },
            "switch_if_not_matching": 0,
            "noMatchDelay": {
                "value": {
                    "value": 0.0,
                    "type": 0
                },
                "unit": 0,
                "version": 1
            },
            "cooldown": {
                "value": {
                    "value": 0.0,
                    "type": 0
                },
                "unit": 0,
                "version": 1
            },
            "enableCooldown": false,
            "active": true,
            "startup_behavior": 0,
            "autoStart": {
                "event": 0,
                "useAutoStartScene": false,
                "sceneSelection": {
                    "type": 0,
                    "name": "",
                    "canvasSelection": "Main"
                },
                "name": "",
                "regexConfig": {
                    "enable": false,
                    "partial": false,
                    "options": 0
                }
            },
            "logLevel": 0,
            "logLevelVersion": 1,
            "showSystemTrayNotifications": false,
            "disableHints": false,
            "disableFilterComboboxFilter": false,
            "warnPluginLoadFailure": true,
            "hideLegacyTabs": true,
            "priority0": 10,
            "priority1": 0,
            "priority2": 2,
            "priority3": 8,
            "priority4": 6,
            "priority5": 9,
            "priority6": 7,
            "priority7": 4,
            "priority8": 1,
            "priority9": 5,
            "priority10": 3,
            "threadPriority": 3,
            "transitionOverrideOverride": false,
            "adjustActiveTransitionType": true,
            "lastImportPath": "",
            "startHotkey": [],
            "stopHotkey": [],
            "toggleHotkey": [],
            "newMacroHotkey": [
                {
                    "control": true,
                    "key": "OBS_KEY_N"
                }
            ],
            "upMacroSegmentHotkey": [],
            "downMacroSegmentHotkey": [],
            "removeMacroSegmentHotkey": [],
            "tabWidgetOrder": [
                {
                    "generalTab": 0
                },
                {
                    "macroTab": 1
                },
                {
                    "windowTitleTab": 2
                },
                {
                    "executableTab": 3
                },
                {
                    "screenRegionTab": 4
                },
                {
                    "mediaTab": 5
                },
                {
                    "fileTab": 6
                },
                {
                    "randomTab": 7
                },
                {
                    "timeTab": 8
                },
                {
                    "idleTab": 9
                },
                {
                    "sceneSequenceTab": 10
                },
                {
                    "audioTab": 11
                },
                {
                    "videoTab": 12
                },
                {
                    "sceneGroupTab": 13
                },
                {
                    "transitionsTab": 14
                },
                {
                    "pauseTab": 15
                },
                {
                    "websocketConnectionTab": 16
                },
                {
                    "httpServerTab": 17
                },
                {
                    "macroScheduleTab": 18
                },
                {
                    "mqttConnectionTab": 19
                },
                {
                    "twitchConnectionTab": 20
                },
                {
                    "actionQueueTab": 21
                },
                {
                    "variableTab": 22
                }
            ],
            "saveWindowGeo": false,
            "windowPosX": 320,
            "windowPosY": 318,
            "windowWidth": 1600,
            "windowHeight": 1200,
            "macroListMacroEditSplitterPosition": [
                {
                    "pos": 326
                },
                {
                    "pos": 1248
                }
            ],
            "version": "d44376e86940fad8fc5a945fc046ae3d953cf964",
            "variables": [],
            "macroSearchSettings": {
                "showAlways": false,
                "searchType": 0,
                "searchString": "",
                "regexConfig": {
                    "enable": false,
                    "partial": false,
                    "options": 0
                }
            },
            "actionQueues": [],
            "suppressCrashDialog": true,
            "tabSettings": {
                "searchType": 0,
                "searchString": "",
                "regexConfig": {
                    "enable": false,
                    "partial": false,
                    "options": 0
                }
            },
            "dockSettings": {
                "searchType": 0,
                "searchString": "",
                "regexConfig": {
                    "enable": false,
                    "partial": false,
                    "options": 0
                }
            },
            "addVariablesDock": false,
            "websocketConnections": [],
            "httpServers": [],
            "macroScheduleEntries": [],
            "mqttConnections": [],
            "twitchConnections": [],
            "dockWindows": {
                "docks": []
            },
            "alwaysShowTabs": false
        }
    },
    "version": 2
}      '';
    in
    ''
      obs_dir="$HOME/.config/obs-studio"
      if [ ! -d "$obs_dir/basic/profiles/Webcam_On" ]; then
        $DRY_RUN_CMD mkdir -p "$obs_dir/basic/profiles/Webcam_On"
        $DRY_RUN_CMD mkdir -p "$obs_dir/basic/scenes"

        $DRY_RUN_CMD cp ${globalIni} "$obs_dir/global.ini"
        $DRY_RUN_CMD chmod 644 "$obs_dir/global.ini"

        $DRY_RUN_CMD cp ${basicIni} "$obs_dir/basic/profiles/Webcam_On/basic.ini"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/basic.ini"

        $DRY_RUN_CMD cp ${serviceJson} "$obs_dir/basic/profiles/Webcam_On/service.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/service.json"

        $DRY_RUN_CMD cp ${streamEncoderJson} "$obs_dir/basic/profiles/Webcam_On/streamEncoder.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/profiles/Webcam_On/streamEncoder.json"

        $DRY_RUN_CMD cp ${userIni} "$obs_dir/user.ini"
        $DRY_RUN_CMD chmod 644 "$obs_dir/user.ini"

        $DRY_RUN_CMD cp ${scenesJson} "$obs_dir/basic/scenes/default.json"
        $DRY_RUN_CMD chmod 644 "$obs_dir/basic/scenes/default.json"

        # Patch Flatpak paths to xdt1-t paths in the seeded scene collection.
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
          -e 's|/var/home/xrs444/Documents/OBS/|/home/xrs444/OBS/images/|g' \
          -e 's|/var/home/xrs444/Videos/|/home/xrs444/OBS/Video/|g' \
          -e 's|/var/home/xrs444/OBS/Audio/|/home/xrs444/OBS/Audio/|g' \
          "$obs_dir/basic/scenes/default.json"
      fi

      # Ensure WebSocket section exists in global.ini (idempotent — runs every activation)
      if [ -f "$obs_dir/global.ini" ] && ! grep -q "\[OBSWebSocket\]" "$obs_dir/global.ini"; then
        printf '\n[OBSWebSocket]\nServerEnabled=true\nServerPort=4455\nAuthRequired=true\nAlertsEnabled=false\n' \
          | $DRY_RUN_CMD tee -a "$obs_dir/global.ini" > /dev/null
      fi
    ''
  );

  # Plugin configs seeded separately so they can be applied even on existing installs.
  home.activation.obsPluginConfigs = lib.hm.dag.entryAfter [ "obsConfig" ] (
    let
      audioMonitorJson = pkgs.writeText "obs-audio-monitor.json" (builtins.toJSON {
        reset_hotkey = [ ];
        showOutputMeter = true;
        showOutputSlider = false;
        showOnlyActive = true;
        showSliderNames = true;
        outputs = [
          {
            devices = [
              {
                id = "alsa_output.pci-0000_0e_00.1.hdmi-stereo";
                locked = false;
                muted = false;
                volume = 100.0;
                name = "Radeon High Definition Audio Controller [Rembrandt/Strix] Digital Stereo (HDMI)";
              }
              {
                id = "alsa_output.pci-0000_10_00.6.iec958-stereo";
                locked = false;
                muted = false;
                volume = 100.0;
                name = "Ryzen HD Audio Controller Digital Stereo (IEC958)";
              }
              {
                id = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
                locked = false;
                muted = false;
                volume = 100.0;
                name = "GB203 High Definition Audio Controller Digital Stereo (HDMI)";
              }
            ];
            enabled = true;
          }
          { enabled = false; }
          { enabled = false; }
          { enabled = false; }
          { enabled = false; }
          { enabled = false; }
        ];
      });

      # server_password is a placeholder — real value injected from sops every
      # activation by home.activation.obsWebsocketSecret below (V3, 2026-07-15).
      obsWebsocketJson = pkgs.writeText "obs-websocket.json" (builtins.toJSON {
        alerts_enabled = true;
        auth_required = true;
        first_load = false;
        server_enabled = true;
        server_password = "set-via-sops-see-obsWebsocketSecret-activation";
        server_port = 4455;
      });
    in
    ''
      obs_dir="$HOME/.config/obs-studio"

      obs_audio_cfg="$obs_dir/plugin_config/audio-monitor/config.json"
      if [ ! -f "$obs_audio_cfg" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$obs_audio_cfg")"
        $DRY_RUN_CMD cp ${audioMonitorJson} "$obs_audio_cfg"
        $DRY_RUN_CMD chmod 644 "$obs_audio_cfg"
      fi

      obs_ws_cfg="$obs_dir/plugin_config/obs-websocket/config.json"
      if [ ! -f "$obs_ws_cfg" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$obs_ws_cfg")"
        $DRY_RUN_CMD cp ${obsWebsocketJson} "$obs_ws_cfg"
        $DRY_RUN_CMD chmod 644 "$obs_ws_cfg"
      fi
    ''
  );

  # Injects the real obs-websocket password from sops every activation, so
  # rotations propagate without needing to delete the seeded config first.
  home.activation.obsWebsocketSecret = lib.hm.dag.entryAfter [ "obsPluginConfigs" ] ''
    obs_ws_cfg="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"
    ws_secret="/run/secrets/obs-websocket-password"
    if [ -f "$obs_ws_cfg" ] && [ -f "$ws_secret" ]; then
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --arg pw "$(cat "$ws_secret")" \
        '.server_password = $pw' "$obs_ws_cfg" > "$obs_ws_cfg.tmp"
      $DRY_RUN_CMD mv "$obs_ws_cfg.tmp" "$obs_ws_cfg"
    fi
  '';

  # Always switch to NVENC, even if the profile was seeded before this change.
  # jim_nvenc = OBS NVENC H.264 encoder (works in OBS 30+, recognised as obs_nvenc_h264_tex alias).
  home.activation.obsNvencEncoder = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "obsConfig" ] ''
      obs_ini="$HOME/.config/obs-studio/basic/profiles/Webcam_On/basic.ini"
      if [ -f "$obs_ini" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
          -e 's|^StreamEncoder=.*|StreamEncoder=nvenc|' \
          -e 's|^RecEncoder=x264$|RecEncoder=nvenc|' \
          -e 's|^Encoder=obs_x264$|Encoder=jim_nvenc|' \
          "$obs_ini"
      fi
    ''
  );

  # Always patch the monitoring device, even if the profile was seeded before this change.
  home.activation.obsMonitoringDevice = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "obsConfig" ] ''
      obs_ini="$HOME/.config/obs-studio/basic/profiles/Webcam_On/basic.ini"
      if [ -f "$obs_ini" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i \
          -e 's|^MonitoringDeviceId=.*|MonitoringDeviceId=combined-obs|' \
          -e 's|^MonitoringDeviceName=.*|MonitoringDeviceName=Pebble + Schiit + SPDIF Out|' \
          "$obs_ini"
      fi
    ''
  );
}
