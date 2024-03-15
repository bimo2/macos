require 'json'
require 'fileutils'

$scheme = nil

def read_define_txt(file)
  themes = []
  tokens = {}

  File.foreach(file) do |line|
    line.strip!
    next if line.empty?

    if line.start_with?('----') && line.end_with?('----')
      theme = line.gsub('----', '').strip.downcase
      themes << theme.gsub(' ', '')
    else
      key_value = line.split(/\s+/, 2)
      tokens[key_value[0]] = key_value[1] if key_value.length == 2
    end
  end

  [themes, tokens]
end

def with_alpha(color, hex_value, dark_hex_value = nil)
  if $scheme == "dark"
    hex_value = dark_hex_value if dark_hex_value
  end

  hex_value = hex_value.rjust(2, '0') if hex_value.length < 2
  color + hex_value
end

def with_brightness(color, value, dark_value = nil)
  if $scheme == "dark"
    value = dark_value if dark_value
  else
    value *= -1
  end

  color = color.gsub("#", "")
  red = color[0..1].to_i(16)
  red += value
  red = [0, [255, red].min].max

  green = color[2..3].to_i(16)
  green += value
  green = [0, [255, green].min].max

  blue = color[4..5].to_i(16)
  blue += value
  blue = [0, [255, blue].min].max

  "#%02x%02x%02x" % [red, green, blue]
end

def map_colors(theme, tokens)
  color_value = lambda do |token|
    token += ".d" if $scheme == "dark"
    value = tokens["#{theme}.#{token}"]
    value ||= tokens[token]
    value
  end

  none = with_alpha(color_value.call("background"), "00")

  options = {
    # https://code.visualstudio.com/api/references/theme-color#base-colors
    "focusBorder" => lambda { color_value.call("accent") },
    "foreground" => lambda { color_value.call("text") },
    # "disabledForeground" => lambda { },
    "widget.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "widget.shadow" => lambda { with_alpha(color_value.call("shadow"), "26", "b3") },
    "selection.background" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "descriptionForeground" => lambda { color_value.call("subtext") },
    "errorForeground" => lambda { color_value.call("error") },
    "icon.foreground" => lambda { color_value.call("text") },
    "sash.hoverBorder" => lambda { color_value.call("accent") },

    # https://code.visualstudio.com/api/references/theme-color#window-border
    # "window.activeBorder" => lambda { },
    # "window.inactiveBorder" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#text-colors
    "textBlockQuote.background" => lambda { with_brightness(color_value.call("background"), 12) },
    "textBlockQuote.border" => lambda { none },
    "textCodeBlock.background" => lambda { with_brightness(color_value.call("background"), 12) },
    "textLink.activeForeground" => lambda { with_brightness(color_value.call("accent"), 24) },
    "textLink.foreground" => lambda { color_value.call("accent") },
    "textPreformat.foreground" => lambda { color_value.call("text") },
    "textPreformat.background" => lambda { with_brightness(color_value.call("background"), 12) },
    "textSeparator.foreground" => lambda { with_brightness(color_value.call("subdued"), 12) },

    # https://code.visualstudio.com/api/references/theme-color#action-colors
    "toolbar.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "toolbar.hoverOutline" => lambda { none },
    "toolbar.activeBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },

    # https://code.visualstudio.com/api/references/theme-color#button-control
    "button.background" => lambda { color_value.call("accent") },
    "button.foreground" => lambda { "#ffffff" },
    "button.border" => lambda { none },
    "button.separator" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "button.hoverBackground" => lambda { with_brightness(color_value.call("accent"), 12) },
    "button.secondaryForeground" => lambda { "#ffffff" },
    "button.secondaryBackground" => lambda { color_value.call("subdued") },
    "button.secondaryHoverBackground" => lambda { with_brightness(color_value.call("subdued"), 12) },
    "checkbox.background" => lambda { with_brightness(color_value.call("background"), 24) },
    "checkbox.foreground" => lambda { color_value.call("text") },
    "checkbox.border" => lambda { none },
    "checkbox.selectBackground" => lambda { with_brightness(color_value.call("background"), 24) },
    "checkbox.selectBorder" => lambda { none },

    # https://code.visualstudio.com/api/references/theme-color#dropdown-control
    "dropdown.background" => lambda { with_brightness(color_value.call("background"), 24) },
    "dropdown.listBackground" => lambda { with_brightness(color_value.call("background"), 24) },
    "dropdown.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "dropdown.foreground" => lambda { color_value.call("text") },

    # https://code.visualstudio.com/api/references/theme-color#input-control
    "input.background" => lambda { with_brightness(color_value.call("background"), 24) },
    "input.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "input.foreground" => lambda { color_value.call("text") },
    "input.placeholderForeground" => lambda { with_alpha(color_value.call("text"), "66") },
    "inputOption.activeBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "inputOption.activeBorder" => lambda { color_value.call("overlay") },
    "inputOption.activeForeground" => lambda { color_value.call("text") },
    "inputOption.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "inputValidation.errorBackground" => lambda { with_brightness(color_value.call("error"), -156) },
    "inputValidation.errorForeground" => lambda { color_value.call("text") },
    "inputValidation.errorBorder" => lambda { color_value.call("error") },
    "inputValidation.infoBackground" => lambda { with_brightness(color_value.call("accent"), -156) },
    "inputValidation.infoForeground" => lambda { color_value.call("text") },
    "inputValidation.infoBorder" => lambda { color_value.call("accent") },
    "inputValidation.warningBackground" => lambda { with_brightness(color_value.call("warning"), -156) },
    "inputValidation.warningForeground" => lambda { color_value.call("text") },
    "inputValidation.warningBorder" => lambda { color_value.call("warning") },

    # https://code.visualstudio.com/api/references/theme-color#scrollbar-control
    "scrollbar.shadow" => lambda { with_alpha(color_value.call("shadow"), "26", "b3") },
    "scrollbarSlider.activeBackground" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "scrollbarSlider.background" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "scrollbarSlider.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },

    # https://code.visualstudio.com/api/references/theme-color#badge
    "badge.foreground" => lambda { "#ffffff" },
    "badge.background" => lambda { color_value.call("accent") },

    # https://code.visualstudio.com/api/references/theme-color#progress-bar
    "progressBar.background" => lambda { color_value.call("accent") },

    # https://code.visualstudio.com/api/references/theme-color#lists-and-trees
    "list.activeSelectionBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "list.activeSelectionForeground" => lambda { color_value.call("text") },
    "list.activeSelectionIconForeground" => lambda { color_value.call("text") },
    "list.dropBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "list.focusBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "list.focusForeground" => lambda { color_value.call("text") },
    "list.focusHighlightForeground" => lambda { color_value.call("text") },
    "list.focusOutline" => lambda { none },
    "list.focusAndSelectionOutline" => lambda { color_value.call("accent") },
    "list.highlightForeground" => lambda { color_value.call("text") },
    "list.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "list.hoverForeground" => lambda { color_value.call("text") },
    "list.inactiveSelectionBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "list.inactiveSelectionForeground" => lambda { color_value.call("text") },
    "list.inactiveSelectionIconForeground" => lambda { color_value.call("text") },
    "list.inactiveFocusBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "list.inactiveFocusOutline" => lambda { none },
    "list.invalidItemForeground" => lambda { color_value.call("error") },
    "list.errorForeground" => lambda { color_value.call("error") },
    "list.warningForeground" => lambda { color_value.call("warning") },
    "listFilterWidget.background" => lambda { color_value.call("background") },
    "listFilterWidget.outline" => lambda { none },
    "listFilterWidget.noMatchesOutline" => lambda { none },
    "listFilterWidget.shadow" => lambda { with_alpha(color_value.call("shadow"), "26", "b3") },
    "list.filterMatchBackground" => lambda { with_alpha(color_value.call("accent"), "99") },
    "list.filterMatchBorder" => lambda { none },
    # "list.deemphasizedForeground" => lambda { },
    "list.dropBetweenBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "tree.indentGuidesStroke" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "tree.inactiveIndentGuidesStroke" => lambda { with_alpha(color_value.call("overlay"), "10") },
    # "tree.tableColumnsBorder" => lambda { },
    # "tree.tableOddRowsBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#activity-bar
    "activityBar.background" => lambda { color_value.call("background") },
    "activityBar.dropBorder" => lambda { color_value.call("overlay") },
    "activityBar.foreground" => lambda { color_value.call("text") },
    "activityBar.inactiveForeground" => lambda { with_alpha(color_value.call("text"), "66", "99") },
    "activityBar.border" => lambda { color_value.call("background") },
    "activityBarBadge.background" => lambda { color_value.call("accent") },
    "activityBarBadge.foreground" => lambda { "#ffffff" },
    "activityBar.activeBorder" => lambda { color_value.call("accent") },
    "activityBar.activeBackground" => lambda { none },
    "activityBar.activeFocusBorder" => lambda { color_value.call("accent") },
    "activityBarTop.foreground" => lambda { color_value.call("text") },
    "activityBarTop.activeBorder" => lambda { color_value.call("accent") },
    "activityBarTop.inactiveForeground" => lambda { with_alpha(color_value.call("text"), "99") },
    "activityBarTop.dropBorder" => lambda { color_value.call("overlay") },

    # https://code.visualstudio.com/api/references/theme-color#profiles
    # "profileBadge.background" => lambda { },
    # "profileBadge.foreground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#side-bar
    "sideBar.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "sideBar.foreground" => lambda { color_value.call("text") },
    "sideBar.border" => lambda { color_value.call("background") },
    "sideBar.dropBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "sideBarTitle.foreground" => lambda { color_value.call("text") },
    "sideBarSectionHeader.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "sideBarSectionHeader.foreground" => lambda { color_value.call("text") },
    "sideBarSectionHeader.border" => lambda { color_value.call("background") },

    # https://code.visualstudio.com/api/references/theme-color#minimap
    "minimap.findMatchHighlight" => lambda { color_value.call("accent") },
    "minimap.selectionHighlight" => lambda { with_alpha(color_value.call("overlay"), "66") },
    "minimap.errorHighlight" => lambda { with_alpha(color_value.call("error"), "66") },
    "minimap.warningHighlight" => lambda { with_alpha(color_value.call("warning"), "66") },
    "minimap.background" => lambda { color_value.call("background") },
    "minimap.selectionOccurrenceHighlight" => lambda { with_alpha(color_value.call("overlay"), "66") },
    "minimap.foregroundOpacity" => lambda { "#000000cc" },
    "minimap.infoHighlight" => lambda { with_alpha(color_value.call("accent"), "66") },
    "minimapSlider.background" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "minimapSlider.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "minimapSlider.activeBackground" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "minimapGutter.addedBackground" => lambda { color_value.call("accent") },
    "minimapGutter.modifiedBackground" => lambda { with_alpha(color_value.call("accent"), "99", "80") },
    "minimapGutter.deletedBackground" => lambda { color_value.call("error") },

    # https://code.visualstudio.com/api/references/theme-color#editor-groups-tabs
    "editorGroup.border" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editorGroup.dropBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorGroupHeader.noTabsBackground" => lambda { color_value.call("background") },
    "editorGroupHeader.tabsBackground" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "editorGroupHeader.tabsBorder" => lambda { color_value.call("background") },
    "editorGroupHeader.border" => lambda { none },
    "editorGroup.emptyBackground" => lambda { color_value.call("background") },
    "editorGroup.focusedEmptyBorder" => lambda { color_value.call("accent") },
    "editorGroup.dropIntoPromptForeground" => lambda { color_value.call("text") },
    "editorGroup.dropIntoPromptBackground" => lambda { color_value.call("accent") },
    "editorGroup.dropIntoPromptBorder" => lambda { none },
    "tab.activeBackground" => lambda { color_value.call("background") },
    "tab.unfocusedActiveBackground" => lambda { color_value.call("background") },
    "tab.activeForeground" => lambda { color_value.call("text") },
    "tab.border" => lambda { color_value.call("background") },
    "tab.activeBorder" => lambda { none },
    "tab.dragAndDropBorder" => lambda { color_value.call("accent") },
    "tab.unfocusedActiveBorder" => lambda { none },
    "tab.activeBorderTop" => lambda { color_value.call("accent") },
    "tab.unfocusedActiveBorderTop" => lambda { color_value.call("accent") },
    "tab.lastPinnedBorder" => lambda { none },
    "tab.inactiveBackground" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "tab.unfocusedInactiveBackground" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "tab.inactiveForeground" => lambda { with_alpha(color_value.call("text"), "b3") },
    "tab.unfocusedActiveForeground" => lambda { color_value.call("text") },
    "tab.unfocusedInactiveForeground" => lambda { with_alpha(color_value.call("text"), "b3") },
    "tab.hoverBackground" => lambda { color_value.call("background") },
    "tab.unfocusedHoverBackground" => lambda { color_value.call("background") },
    "tab.hoverForeground" => lambda { color_value.call("text") },
    "tab.unfocusedHoverForeground" => lambda { with_alpha(color_value.call("text"), "b3") },
    "tab.hoverBorder" => lambda { none },
    "tab.unfocusedHoverBorder" => lambda { none },
    "tab.activeModifiedBorder" => lambda { color_value.call("overlay") },
    "tab.inactiveModifiedBorder" => lambda { none },
    "tab.unfocusedActiveModifiedBorder" => lambda { color_value.call("overlay") },
    "tab.unfocusedInactiveModifiedBorder" => lambda { none },
    "editorPane.background" => lambda { color_value.call("background") },
    "sideBySideEditor.horizontalBorder" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "sideBySideEditor.verticalBorder" => lambda { with_alpha(color_value.call("overlay"), "20") },

    # https://code.visualstudio.com/api/references/theme-color#editor-colors
    "editor.background" => lambda { color_value.call("background") },
    "editor.foreground" => lambda { color_value.call("text") },
    "editorLineNumber.foreground" => lambda { with_alpha(color_value.call("text"), "33") },
    "editorLineNumber.activeForeground" => lambda { color_value.call("text") },
    # "editorLineNumber.dimmedForeground" => lambda { },
    "editorCursor.background" => lambda { color_value.call("background") },
    "editorCursor.foreground" => lambda { color_value.call("overlay") },
    "editor.selectionBackground" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "editor.selectionForeground" => lambda { color_value.call("text") },
    "editor.inactiveSelectionBackground" => lambda { none },
    "editor.selectionHighlightBackground" => lambda { none },
    "editor.selectionHighlightBorder" => lambda { color_value.call("overlay") },
    "editor.wordHighlightBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editor.wordHighlightBorder" => lambda { none },
    "editor.wordHighlightStrongBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editor.wordHighlightStrongBorder" => lambda { none },
    "editor.wordHighlightTextBackground" => lambda { with_alpha(color_value.call("overlay"), "1a") },
    "editor.wordHighlightTextBorder" => lambda { none },
    "editor.findMatchBackground" => lambda { with_alpha(color_value.call("accent"), "99") },
    "editor.findMatchHighlightBackground" => lambda { with_alpha(color_value.call("accent"), "4d") },
    "editor.findRangeHighlightBackground" => lambda { with_alpha(color_value.call("accent"), "4d") },
    "editor.findMatchBorder" => lambda { none },
    "editor.findMatchHighlightBorder" => lambda { none },
    "editor.findRangeHighlightBorder" => lambda { none },
    "search.resultsInfoForeground" => lambda { color_value.call("text") },
    "searchEditor.findMatchBackground" => lambda { with_alpha(color_value.call("accent"), "99") },
    "searchEditor.findMatchBorder" => lambda { none },
    "searchEditor.textInputBorder" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editor.hoverHighlightBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editor.lineHighlightBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editor.lineHighlightBorder" => lambda { none },
    "editorWatermark.foreground" => lambda { with_alpha(color_value.call("text"), "99") },
    "editorUnicodeHighlight.border" => lambda { none },
    "editorUnicodeHighlight.background" => lambda { none },
    "editorLink.activeForeground" => lambda { color_value.call("accent") },
    "editor.rangeHighlightBackground" => lambda { with_alpha(color_value.call("accent"), "4d") },
    "editor.rangeHighlightBorder" => lambda { none },
    "editor.symbolHighlightBackground" => lambda { with_alpha(color_value.call("accent"), "4d") },
    "editor.symbolHighlightBorder" => lambda { none },
    "editorWhitespace.foreground" => lambda { with_alpha(color_value.call("overlay"), "33") },
    "editorIndentGuide.background" => lambda { with_alpha(color_value.call("overlay"), "10") },
    # "editorIndentGuide.background1" => lambda { },
    # "editorIndentGuide.background2" => lambda { },
    # "editorIndentGuide.background3" => lambda { },
    # "editorIndentGuide.background4" => lambda { },
    # "editorIndentGuide.background5" => lambda { },
    # "editorIndentGuide.background6" => lambda { },
    "editorIndentGuide.activeBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    # "editorIndentGuide.activeBackground1" => lambda { },
    # "editorIndentGuide.activeBackground2" => lambda { },
    # "editorIndentGuide.activeBackground3" => lambda { },
    # "editorIndentGuide.activeBackground4" => lambda { },
    # "editorIndentGuide.activeBackground5" => lambda { },
    # "editorIndentGuide.activeBackground6" => lambda { },
    "editorInlayHint.background" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editorInlayHint.foreground" => lambda { color_value.call("text") },
    "editorInlayHint.typeForeground" => lambda { color_value.call("text") },
    "editorInlayHint.typeBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editorInlayHint.parameterForeground" => lambda { color_value.call("text") },
    "editorInlayHint.parameterBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editorRuler.foreground" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "editor.linkedEditingBackground" => lambda { color_value.call("background") },
    "editorCodeLens.foreground" => lambda { color_value.call("subtext") },
    "editorLightBulb.foreground" => lambda { color_value.call("text") },
    "editorLightBulbAutoFix.foreground" => lambda { color_value.call("text") },
    "editorLightBulbAi.foreground" => lambda { color_value.call("text") },
    "editorBracketMatch.background" => lambda { none },
    "editorBracketMatch.border" => lambda { color_value.call("accent") },
    "editorBracketHighlight.foreground1" => lambda { color_value.call("text") },
    "editorBracketHighlight.foreground2" => lambda { color_value.call("text") },
    "editorBracketHighlight.foreground3" => lambda { color_value.call("text") },
    "editorBracketHighlight.foreground4" => lambda { color_value.call("text") },
    "editorBracketHighlight.foreground5" => lambda { color_value.call("text") },
    "editorBracketHighlight.foreground6" => lambda { color_value.call("text") },
    "editorBracketHighlight.unexpectedBracket.foreground" => lambda { color_value.call("error") },
    "editorBracketPairGuide.activeBackground1" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.activeBackground2" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.activeBackground3" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.activeBackground4" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.activeBackground5" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.activeBackground6" => lambda { with_alpha(color_value.call("accent"), "40") },
    "editorBracketPairGuide.background1" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorBracketPairGuide.background2" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorBracketPairGuide.background3" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorBracketPairGuide.background4" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorBracketPairGuide.background5" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorBracketPairGuide.background6" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editor.foldBackground" => lambda { with_alpha(color_value.call("overlay"), "0a") },
    "editorOverviewRuler.background" => lambda { color_value.call("background") },
    "editorOverviewRuler.border" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "editorOverviewRuler.findMatchForeground" => lambda { color_value.call("accent") },
    "editorOverviewRuler.rangeHighlightForeground" => lambda { color_value.call("overlay") },
    "editorOverviewRuler.selectionHighlightForeground" => lambda { color_value.call("overlay") },
    "editorOverviewRuler.wordHighlightForeground" => lambda { color_value.call("overlay") },
    "editorOverviewRuler.wordHighlightStrongForeground" => lambda { color_value.call("overlay") },
    "editorOverviewRuler.wordHighlightTextForeground" => lambda { color_value.call("overlay") },
    "editorOverviewRuler.modifiedForeground" => lambda { with_alpha(color_value.call("accent"), "99", "80") },
    "editorOverviewRuler.addedForeground" => lambda { color_value.call("accent") },
    "editorOverviewRuler.deletedForeground" => lambda { color_value.call("error") },
    "editorOverviewRuler.errorForeground" => lambda { color_value.call("error") },
    "editorOverviewRuler.warningForeground" => lambda { color_value.call("warning") },
    "editorOverviewRuler.infoForeground" => lambda { color_value.call("accent") },
    "editorOverviewRuler.bracketMatchForeground" => lambda { none },
    "editorOverviewRuler.inlineChatInserted" => lambda { none },
    "editorOverviewRuler.inlineChatRemoved" => lambda { none },
    "editorError.foreground" => lambda { color_value.call("error") },
    "editorError.border" => lambda { none },
    "editorError.background" => lambda { none },
    "editorWarning.foreground" => lambda { color_value.call("warning") },
    "editorWarning.border" => lambda { none },
    "editorWarning.background" => lambda { none },
    "editorInfo.foreground" => lambda { color_value.call("accent") },
    "editorInfo.border" => lambda { none },
    "editorInfo.background" => lambda { none },
    "editorHint.foreground" => lambda { none },
    "editorHint.border" => lambda { with_alpha(color_value.call("accent"), "40") },
    "problemsErrorIcon.foreground" => lambda { color_value.call("error") },
    "problemsWarningIcon.foreground" => lambda { color_value.call("warning") },
    "problemsInfoIcon.foreground" => lambda { color_value.call("accent") },
    "editorUnnecessaryCode.border" => lambda { none },
    "editorUnnecessaryCode.opacity" => lambda { "#00000033" },
    "editorGutter.background" => lambda { color_value.call("background") },
    "editorGutter.modifiedBackground" => lambda { with_alpha(color_value.call("accent"), "99", "80") },
    "editorGutter.addedBackground" => lambda { color_value.call("accent") },
    "editorGutter.deletedBackground" => lambda { color_value.call("error") },
    # "editorGutter.commentRangeForeground" => lambda { },
    # "editorGutter.commentGlyphForeground" => lambda { },
    # "editorGutter.commentUnresolvedGlyphForeground" => lambda { },
    "editorGutter.foldingControlForeground" => lambda { color_value.call("overlay") },
    # "editorCommentsWidget.resolvedBorder" => lambda { },
    # "editorCommentsWidget.unresolvedBorder" => lambda { },
    # "editorCommentsWidget.rangeBackground" => lambda { },
    # "editorCommentsWidget.rangeActiveBackground" => lambda { },
    # "editorCommentsWidget.replyInputBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#diff-editor-colors
    "diffEditor.insertedTextBackground" => lambda { with_alpha(color_value.call("accent"), "66") },
    "diffEditor.insertedTextBorder" => lambda { none },
    "diffEditor.removedTextBackground" => lambda { with_alpha(color_value.call("error"), "66") },
    "diffEditor.removedTextBorder" => lambda { none },
    "diffEditor.border" => lambda { with_alpha(color_value.call("overlay"), "20") },
    # "diffEditor.diagonalFill" => lambda { },
    "diffEditor.insertedLineBackground" => lambda { with_alpha(color_value.call("accent"), "33") },
    "diffEditor.removedLineBackground" => lambda { with_alpha(color_value.call("error"), "33") },
    # "diffEditorGutter.insertedLineBackground" => lambda { },
    # "diffEditorGutter.removedLineBackground" => lambda { },
    # "diffEditorOverview.insertedForeground" => lambda { },
    # "diffEditorOverview.removedForeground" => lambda { },
    # "diffEditor.unchangedRegionBackground" => lambda { },
    # "diffEditor.unchangedRegionForeground" => lambda { },
    # "diffEditor.unchangedRegionShadow" => lambda { },
    # "diffEditor.unchangedCodeBackground" => lambda { },
    # "diffEditor.move.border" => lambda { },
    # "diffEditor.moveActive.border" => lambda { },
    # "multiDiffEditor.headerBackground" => lambda { },
    # "multiDiffEditor.background" => lambda { },
    # "multiDiffEditor.border" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#chat-colors
    # "chat.requestBorder" => lambda { },
    # "chat.requestBackground" => lambda { },
    # "chat.slashCommandBackground" => lambda { },
    # "chat.slashCommandForeground" => lambda { },
    # "chat.avatarBackground" => lambda { },
    # "chat.avatarForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#inline-chat-colors
    # "inlineChat.background" => lambda { },
    # "inlineChat.border" => lambda { },
    # "inlineChat.shadow" => lambda { },
    # "inlineChat.regionHighlight" => lambda { },
    # "inlineChatInput.border" => lambda { },
    # "inlineChatInput.focusBorder" => lambda { },
    # "inlineChatInput.placeholderForeground" => lambda { },
    # "inlineChatInput.background" => lambda { },
    # "inlineChatDiff.inserted" => lambda { },
    # "inlineChatDiff.removed" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#panel-chat-colors
    # "interactive.activeCodeBorder" => lambda { },
    # "interactive.inactiveCodeBorder" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#editor-widget-colors
    "editorWidget.foreground" => lambda { color_value.call("text") },
    "editorWidget.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "editorWidget.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "editorWidget.resizeBorder" => lambda { color_value.call("overlay") },
    # "editorSuggestWidget.background" => lambda { },
    # "editorSuggestWidget.border" => lambda { },
    "editorSuggestWidget.foreground" => lambda { color_value.call("text") },
    # "editorSuggestWidget.focusHighlightForeground" => lambda { },
    # "editorSuggestWidget.highlightForeground" => lambda { },
    "editorSuggestWidget.selectedBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    # "editorSuggestWidget.selectedForeground" => lambda { },
    # "editorSuggestWidget.selectedIconForeground" => lambda { },
    # "editorSuggestWidgetStatus.foreground" => lambda { },
    # "editorHoverWidget.foreground" => lambda { },
    # "editorHoverWidget.background" => lambda { },
    # "editorHoverWidget.border" => lambda { },
    # "editorHoverWidget.highlightForeground" => lambda { },
    # "editorHoverWidget.statusBarBackground" => lambda { },
    # "editorGhostText.border" => lambda { },
    # "editorGhostText.background" => lambda { },
    # "editorGhostText.foreground" => lambda { },
    # "editorStickyScroll.background" => lambda { },
    # "editorStickyScroll.border" => lambda { },
    "editorStickyScroll.shadow" => lambda { with_alpha(color_value.call("shadow"), "26", "b3") },
    "editorStickyScrollHover.background" => lambda { with_alpha(color_value.call("overlay"), "10") },
    # "debugExceptionWidget.background" => lambda { },
    # "debugExceptionWidget.border" => lambda { },
    # "editorMarkerNavigation.background" => lambda { },
    # "editorMarkerNavigationError.background" => lambda { },
    # "editorMarkerNavigationWarning.background" => lambda { },
    # "editorMarkerNavigationInfo.background" => lambda { },
    # "editorMarkerNavigationError.headerBackground" => lambda { },
    # "editorMarkerNavigationWarning.headerBackground" => lambda { },
    # "editorMarkerNavigationInfo.headerBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#peek-view-colors
    "peekView.border" => lambda { color_value.call("accent") },
    "peekViewEditor.background" => lambda { color_value.call("background") },
    "peekViewEditorGutter.background" => lambda { color_value.call("background") },
    # "peekViewEditor.matchHighlightBackground" => lambda { },
    # "peekViewEditor.matchHighlightBorder" => lambda { },
    # "peekViewResult.background" => lambda { },
    # "peekViewResult.fileForeground" => lambda { },
    # "peekViewResult.lineForeground" => lambda { },
    # "peekViewResult.matchHighlightBackground" => lambda { },
    # "peekViewResult.selectionBackground" => lambda { },
    # "peekViewResult.selectionForeground" => lambda { },
    "peekViewTitle.background" => lambda { color_value.call("background") },
    "peekViewTitleDescription.foreground" => lambda { color_value.call("subtext") },
    "peekViewTitleLabel.foreground" => lambda { color_value.call("text") },
    "peekViewEditorStickyScroll.background" => lambda { color_value.call("background") },

    # https://code.visualstudio.com/api/references/theme-color#merge-conflicts-colors
    "merge.currentHeaderBackground" => lambda { with_alpha(with_brightness(color_value.call("accent"), 32), "b3") },
    "merge.currentContentBackground" => lambda { with_alpha(with_brightness(color_value.call("accent"), 32), "33") },
    "merge.incomingHeaderBackground" => lambda { with_alpha(with_brightness(color_value.call("accent"), -32), "b3") },
    "merge.incomingContentBackground" => lambda { with_alpha(with_brightness(color_value.call("accent"), -32), "33") },
    "merge.border" => lambda { none },
    "merge.commonContentBackground" => lambda { with_alpha(with_brightness(color_value.call("background"), 32), "33") },
    "merge.commonHeaderBackground" => lambda { with_alpha(with_brightness(color_value.call("background"), 32), "b3") },
    "editorOverviewRuler.currentContentForeground" => lambda { with_brightness(color_value.call("accent"), 32) },
    "editorOverviewRuler.incomingContentForeground" => lambda { with_brightness(color_value.call("accent"), -32) },
    "editorOverviewRuler.commonContentForeground" => lambda { with_brightness(color_value.call("background"), 32) },
    "editorOverviewRuler.commentForeground" => lambda { none },
    "editorOverviewRuler.commentUnresolvedForeground" => lambda { none },
    # "mergeEditor.change.background" => lambda { },
    # "mergeEditor.change.word.background" => lambda { },
    # "mergeEditor.conflict.unhandledUnfocused.border" => lambda { },
    # "mergeEditor.conflict.unhandledFocused.border" => lambda { },
    # "mergeEditor.conflict.handledUnfocused.border" => lambda { },
    # "mergeEditor.conflict.handledFocused.border" => lambda { },
    # "mergeEditor.conflict.handled.minimapOverViewRuler" => lambda { },
    # "mergeEditor.conflict.unhandled.minimapOverViewRuler" => lambda { },
    # "mergeEditor.conflictingLines.background" => lambda { },
    # "mergeEditor.changeBase.background" => lambda { },
    # "mergeEditor.changeBase.word.background" => lambda { },
    # "mergeEditor.conflict.input1.background" => lambda { },
    # "mergeEditor.conflict.input2.background" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#panel-colors
    "panel.background" => lambda { color_value.call("background") },
    "panel.border" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "panel.dropBorder" => lambda { color_value.call("overlay") },
    "panelTitle.activeBorder" => lambda { color_value.call("accent") },
    "panelTitle.activeForeground" => lambda { color_value.call("text") },
    "panelTitle.inactiveForeground" => lambda { with_alpha(color_value.call("overlay"), "cc") },
    "panelInput.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "panelSection.border" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "panelSection.dropBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "panelSectionHeader.background" => lambda { color_value.call("background") },
    "panelSectionHeader.foreground" => lambda { color_value.call("text") },
    "panelSectionHeader.border" => lambda { color_value.call("background") },
    "outputView.background" => lambda { color_value.call("background") },
    "outputViewStickyScroll.background" => lambda { color_value.call("background") },

    # https://code.visualstudio.com/api/references/theme-color#status-bar-colors
    "statusBar.background" => lambda { color_value.call("accent") },
    "statusBar.foreground" => lambda { "#ffffff" },
    "statusBar.border" => lambda { none },
    "statusBar.debuggingBackground" => lambda { color_value.call("debug") },
    "statusBar.debuggingForeground" => lambda { "#ffffff" },
    "statusBar.debuggingBorder" => lambda { none },
    "statusBar.noFolderForeground" => lambda { color_value.call("text") },
    "statusBar.noFolderBackground" => lambda { color_value.call("background") },
    "statusBar.noFolderBorder" => lambda { none },
    "statusBarItem.activeBackground" => lambda { with_alpha(color_value.call("overlay"), "33") },
    "statusBarItem.hoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.hoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.prominentForeground" => lambda { color_value.call("text") },
    "statusBarItem.prominentBackground" => lambda { none },
    "statusBarItem.prominentHoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.prominentHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.remoteBackground" => lambda { none },
    "statusBarItem.remoteForeground" => lambda { "#ffffff" },
    "statusBarItem.remoteHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.remoteHoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.errorBackground" => lambda { none },
    "statusBarItem.errorForeground" => lambda { color_value.call("text") },
    "statusBarItem.errorHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.errorHoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.warningBackground" => lambda { none },
    "statusBarItem.warningForeground" => lambda { color_value.call("text") },
    "statusBarItem.warningHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.warningHoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.compactHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "statusBarItem.focusBorder" => lambda { none },
    "statusBar.focusBorder" => lambda { none },
    "statusBarItem.offlineBackground" => lambda { none },
    "statusBarItem.offlineForeground" => lambda { color_value.call("text") },
    "statusBarItem.offlineHoverForeground" => lambda { color_value.call("text") },
    "statusBarItem.offlineHoverBackground" => lambda { with_alpha(color_value.call("overlay"), "10") },

    # https://code.visualstudio.com/api/references/theme-color#title-bar-colors
    "titleBar.activeBackground" => lambda { color_value.call("background") },
    "titleBar.activeForeground" => lambda { color_value.call("text") },
    "titleBar.inactiveBackground" => lambda { color_value.call("background") },
    "titleBar.inactiveForeground" => lambda { with_alpha(color_value.call("text"), "b3") },
    "titleBar.border" => lambda { none },

    # https://code.visualstudio.com/api/references/theme-color#menu-bar-colors
    # "menubar.selectionForeground" => lambda { },
    # "menubar.selectionBackground" => lambda { },
    # "menubar.selectionBorder" => lambda { },
    # "menu.foreground" => lambda { },
    # "menu.background" => lambda { },
    # "menu.selectionForeground" => lambda { },
    # "menu.selectionBackground" => lambda { },
    # "menu.selectionBorder" => lambda { },
    # "menu.separatorBackground" => lambda { },
    # "menu.border" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#command-center-colors
    # "commandCenter.foreground" => lambda { },
    # "commandCenter.activeForeground" => lambda { },
    # "commandCenter.background" => lambda { },
    # "commandCenter.activeBackground" => lambda { },
    # "commandCenter.border" => lambda { },
    # "commandCenter.inactiveForeground" => lambda { },
    # "commandCenter.inactiveBorder" => lambda { },
    # "commandCenter.activeBorder" => lambda { },
    # "commandCenter.debuggingBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#notification-colors
    "notificationCenter.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "notificationCenterHeader.foreground" => lambda { color_value.call("text") },
    "notificationCenterHeader.background" => lambda { color_value.call("background") },
    "notificationToast.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "notifications.foreground" => lambda { color_value.call("text") },
    "notifications.background" => lambda { color_value.call("background") },
    "notifications.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "notificationLink.foreground" => lambda { color_value.call("accent") },
    "notificationsErrorIcon.foreground" => lambda { color_value.call("error") },
    "notificationsWarningIcon.foreground" => lambda { color_value.call("warning") },
    "notificationsInfoIcon.foreground" => lambda { color_value.call("accent") },

    # https://code.visualstudio.com/api/references/theme-color#banner-colors
    "banner.background" => lambda { color_value.call("accent") },
    "banner.foreground" => lambda { "#ffffff" },
    "banner.iconForeground" => lambda { "#ffffff" },

    # https://code.visualstudio.com/api/references/theme-color#extensions-colors
    # "extensionButton.prominentForeground" => lambda { },
    # "extensionButton.prominentBackground" => lambda { },
    # "extensionButton.prominentHoverBackground" => lambda { },
    # "extensionButton.background" => lambda { },
    # "extensionButton.foreground" => lambda { },
    # "extensionButton.hoverBackground" => lambda { },
    # "extensionButton.separator" => lambda { },
    # "extensionBadge.remoteBackground" => lambda { },
    # "extensionBadge.remoteForeground" => lambda { },
    "extensionIcon.starForeground" => lambda { with_brightness(color_value.call("accent"), 24) },
    "extensionIcon.verifiedForeground" => lambda { with_brightness(color_value.call("accent"), 24) },
    # "extensionIcon.preReleaseForeground" => lambda { },
    # "extensionIcon.sponsorForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#quick-picker-colors
    "pickerGroup.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    "pickerGroup.foreground" => lambda { color_value.call("text") },
    "quickInput.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "quickInput.foreground" => lambda { color_value.call("text") },
    "quickInputList.focusBackground" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "quickInputList.focusForeground" => lambda { color_value.call("text") },
    "quickInputList.focusIconForeground" => lambda { color_value.call("text") },
    "quickInputTitle.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },

    # https://code.visualstudio.com/api/references/theme-color#keybinding-label-colors
    "keybindingLabel.background" => lambda { with_alpha(color_value.call("text"), "10") },
    "keybindingLabel.foreground" => lambda { color_value.call("text") },
    "keybindingLabel.border" => lambda { with_alpha(color_value.call("text"), "99") },
    "keybindingLabel.bottomBorder" => lambda { with_alpha(color_value.call("text"), "99") },

    # https://code.visualstudio.com/api/references/theme-color#keyboard-shortcut-table-colors
    # "keybindingTable.headerBackground" => lambda { },
    # "keybindingTable.rowsBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#integrated-terminal-colors
    "terminal.background" => lambda { color_value.call("background") },
    "terminal.border" => lambda { none },
    "terminal.foreground" => lambda { color_value.call("text") },
    # "terminal.ansiBlack" => lambda { },
    # "terminal.ansiBlue" => lambda { },
    # "terminal.ansiBrightBlack" => lambda { },
    # "terminal.ansiBrightBlue" => lambda { },
    # "terminal.ansiBrightCyan" => lambda { },
    # "terminal.ansiBrightGreen" => lambda { },
    # "terminal.ansiBrightMagenta" => lambda { },
    # "terminal.ansiBrightRed" => lambda { },
    # "terminal.ansiBrightWhite" => lambda { },
    # "terminal.ansiBrightYellow" => lambda { },
    # "terminal.ansiCyan" => lambda { },
    # "terminal.ansiGreen" => lambda { },
    # "terminal.ansiMagenta" => lambda { },
    # "terminal.ansiRed" => lambda { },
    # "terminal.ansiWhite" => lambda { },
    # "terminal.ansiYellow" => lambda { },
    "terminal.selectionBackground" => lambda { with_alpha(color_value.call("overlay"), "40") },
    "terminal.selectionForeground" => lambda { color_value.call("text") },
    "terminal.inactiveSelectionBackground" => lambda { none },
    "terminal.findMatchBackground" => lambda { with_alpha(color_value.call("accent"), "99") },
    "terminal.findMatchBorder" => lambda { none },
    "terminal.findMatchHighlightBackground" => lambda { with_alpha(color_value.call("accent"), "4d") },
    "terminal.findMatchHighlightBorder" => lambda { none },
    "terminal.hoverHighlightBackground" => lambda { with_alpha(color_value.call("overlay"), "20") },
    "terminalCursor.background" => lambda { color_value.call("background") },
    "terminalCursor.foreground" => lambda { color_value.call("overlay") },
    "terminal.dropBackground" => lambda { with_alpha(color_value.call("accent"), "40") },
    "terminal.tab.activeBorder" => lambda { color_value.call("accent") },
    "terminalCommandDecoration.defaultBackground" => lambda { with_alpha(color_value.call("overlay"), "80") },
    "terminalCommandDecoration.successBackground" => lambda { color_value.call("accent") },
    "terminalCommandDecoration.errorBackground" => lambda { color_value.call("error") },
    # "terminalOverviewRuler.cursorForeground" => lambda { },
    # "terminalOverviewRuler.findMatchForeground" => lambda { },
    # "terminalStickyScroll.background" => lambda { },
    # "terminalStickyScrollHover.background" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#debug-colors
    "debugToolBar.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },
    "debugToolBar.border" => lambda { with_alpha(color_value.call("overlay"), "10") },
    # "editor.stackFrameHighlightBackground" => lambda { },
    # "editor.focusedStackFrameHighlightBackground" => lambda { },
    # "editor.inlineValuesForeground" => lambda { },
    # "editor.inlineValuesBackground" => lambda { },
    # "debugView.exceptionLabelForeground" => lambda { },
    # "debugView.exceptionLabelBackground" => lambda { },
    # "debugView.stateLabelForeground" => lambda { },
    # "debugView.stateLabelBackground" => lambda { },
    # "debugView.valueChangedHighlight" => lambda { },
    # "debugTokenExpression.name" => lambda { },
    # "debugTokenExpression.value" => lambda { },
    # "debugTokenExpression.string" => lambda { },
    # "debugTokenExpression.boolean" => lambda { },
    # "debugTokenExpression.number" => lambda { },
    # "debugTokenExpression.error" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#testing-colors
    # "testing.iconFailed" => lambda { },
    # "testing.iconErrored" => lambda { },
    # "testing.iconPassed" => lambda { },
    # "testing.runAction" => lambda { },
    # "testing.iconQueued" => lambda { },
    # "testing.iconUnset" => lambda { },
    # "testing.iconSkipped" => lambda { },
    # "testing.peekBorder" => lambda { },
    # "testing.peekHeaderBackground" => lambda { },
    # "testing.message.error.decorationForeground" => lambda { },
    # "testing.message.error.lineBackground" => lambda { },
    # "testing.message.info.decorationForeground" => lambda { },
    # "testing.message.info.lineBackground" => lambda { },
    # "testing.messagePeekBorder" => lambda { },
    # "testing.messagePeekHeaderBackground" => lambda { },
    # "testing.coveredBackground" => lambda { },
    # "testing.coveredBorder" => lambda { },
    # "testing.coveredGutterBackground" => lambda { },
    # "testing.uncoveredBranchBackground" => lambda { },
    # "testing.uncoveredBackground" => lambda { },
    # "testing.uncoveredBorder" => lambda { },
    # "testing.uncoveredGutterBackground" => lambda { },
    # "testing.coverCountBadgeBackground" => lambda { },
    # "testing.coverCountBadgeForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#welcome-page-colors
    # "welcomePage.background" => lambda { },
    # "welcomePage.progress.background" => lambda { },
    # "welcomePage.progress.foreground" => lambda { },
    # "welcomePage.tileBackground" => lambda { },
    # "welcomePage.tileHoverBackground" => lambda { },
    # "welcomePage.tileBorder" => lambda { },
    # "walkThrough.embeddedEditorBackground" => lambda { },
    # "walkthrough.stepTitle.foreground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#git-colors
    "gitDecoration.addedResourceForeground" => lambda { with_brightness(color_value.call("added"), -20) },
    "gitDecoration.modifiedResourceForeground" => lambda { with_brightness(color_value.call("added"), 40) },
    "gitDecoration.deletedResourceForeground" => lambda { with_brightness(color_value.call("deleted"), 20) },
    "gitDecoration.renamedResourceForeground" => lambda { with_brightness(color_value.call("untracked"), 40) },
    "gitDecoration.stageModifiedResourceForeground" => lambda { with_brightness(color_value.call("added"), -20) },
    "gitDecoration.stageDeletedResourceForeground" => lambda { with_brightness(color_value.call("deleted"), -10) },
    "gitDecoration.untrackedResourceForeground" => lambda { with_brightness(color_value.call("untracked"), 40) },
    "gitDecoration.ignoredResourceForeground" => lambda { with_alpha(color_value.call("text"), "80", "66") },
    "gitDecoration.conflictingResourceForeground" => lambda { with_brightness(color_value.call("added"), 80) },
    "gitDecoration.submoduleResourceForeground" => lambda { color_value.call("text") },

    # https://code.visualstudio.com/api/references/theme-color#settings-editor-colors
    # "settings.headerForeground" => lambda { },
    "settings.modifiedItemIndicator" => lambda { color_value.call("accent") },
    # "settings.dropdownBackground" => lambda { },
    # "settings.dropdownForeground" => lambda { },
    # "settings.dropdownBorder" => lambda { },
    # "settings.dropdownListBorder" => lambda { },
    # "settings.checkboxBackground" => lambda { },
    # "settings.checkboxForeground" => lambda { },
    # "settings.checkboxBorder" => lambda { },
    # "settings.rowHoverBackground" => lambda { },
    # "settings.textInputBackground" => lambda { },
    # "settings.textInputForeground" => lambda { },
    # "settings.textInputBorder" => lambda { },
    # "settings.numberInputBackground" => lambda { },
    # "settings.numberInputForeground" => lambda { },
    # "settings.numberInputBorder" => lambda { },
    # "settings.focusedRowBackground" => lambda { },
    # "settings.focusedRowBorder" => lambda { },
    # "settings.headerBorder" => lambda { },
    # "settings.sashBorder" => lambda { },
    # "settings.settingsHeaderHoverForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#breadcrumbs-colors
    "breadcrumb.foreground" => lambda { with_alpha(color_value.call("text"), "b3") },
    "breadcrumb.background" => lambda { color_value.call("background") },
    "breadcrumb.focusForeground" => lambda { color_value.call("text") },
    "breadcrumb.activeSelectionForeground" => lambda { color_value.call("text") },
    "breadcrumbPicker.background" => lambda { with_brightness(color_value.call("background"), 12, 6) },

    # https://code.visualstudio.com/api/references/theme-color#snippets-colors
    # "editor.snippetTabstopHighlightBackground" => lambda { },
    # "editor.snippetTabstopHighlightBorder" => lambda { },
    # "editor.snippetFinalTabstopHighlightBackground" => lambda { },
    # "editor.snippetFinalTabstopHighlightBorder" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#symbol-icons-colors
    # "symbolIcon.arrayForeground" => lambda { },
    # "symbolIcon.booleanForeground" => lambda { },
    # "symbolIcon.classForeground" => lambda { },
    # "symbolIcon.colorForeground" => lambda { },
    # "symbolIcon.constantForeground" => lambda { },
    # "symbolIcon.constructorForeground" => lambda { },
    # "symbolIcon.enumeratorForeground" => lambda { },
    # "symbolIcon.enumeratorMemberForeground" => lambda { },
    # "symbolIcon.eventForeground" => lambda { },
    # "symbolIcon.fieldForeground" => lambda { },
    # "symbolIcon.fileForeground" => lambda { },
    # "symbolIcon.folderForeground" => lambda { },
    # "symbolIcon.functionForeground" => lambda { },
    # "symbolIcon.interfaceForeground" => lambda { },
    # "symbolIcon.keyForeground" => lambda { },
    # "symbolIcon.keywordForeground" => lambda { },
    # "symbolIcon.methodForeground" => lambda { },
    # "symbolIcon.moduleForeground" => lambda { },
    # "symbolIcon.namespaceForeground" => lambda { },
    # "symbolIcon.nullForeground" => lambda { },
    # "symbolIcon.numberForeground" => lambda { },
    # "symbolIcon.objectForeground" => lambda { },
    # "symbolIcon.operatorForeground" => lambda { },
    # "symbolIcon.packageForeground" => lambda { },
    # "symbolIcon.propertyForeground" => lambda { },
    # "symbolIcon.referenceForeground" => lambda { },
    # "symbolIcon.snippetForeground" => lambda { },
    # "symbolIcon.stringForeground" => lambda { },
    # "symbolIcon.structForeground" => lambda { },
    # "symbolIcon.textForeground" => lambda { },
    # "symbolIcon.typeParameterForeground" => lambda { },
    # "symbolIcon.unitForeground" => lambda { },
    # "symbolIcon.variableForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#debug-icons-colors
    # "debugIcon.breakpointForeground" => lambda { },
    # "debugIcon.breakpointDisabledForeground" => lambda { },
    # "debugIcon.breakpointUnverifiedForeground" => lambda { },
    # "debugIcon.breakpointCurrentStackframeForeground" => lambda { },
    # "debugIcon.breakpointStackframeForeground" => lambda { },
    # "debugIcon.startForeground" => lambda { },
    # "debugIcon.pauseForeground" => lambda { },
    # "debugIcon.stopForeground" => lambda { },
    # "debugIcon.disconnectForeground" => lambda { },
    # "debugIcon.restartForeground" => lambda { },
    # "debugIcon.stepOverForeground" => lambda { },
    # "debugIcon.stepIntoForeground" => lambda { },
    # "debugIcon.stepOutForeground" => lambda { },
    # "debugIcon.continueForeground" => lambda { },
    # "debugIcon.stepBackForeground" => lambda { },
    # "debugConsole.infoForeground" => lambda { },
    # "debugConsole.warningForeground" => lambda { },
    # "debugConsole.errorForeground" => lambda { },
    # "debugConsole.sourceForeground" => lambda { },
    # "debugConsoleInputIcon.foreground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#notebook-colors
    # "notebook.editorBackground" => lambda { },
    # "notebook.cellBorderColor" => lambda { },
    # "notebook.cellHoverBackground" => lambda { },
    # "notebook.cellInsertionIndicator" => lambda { },
    # "notebook.cellStatusBarItemHoverBackground" => lambda { },
    # "notebook.cellToolbarSeparator" => lambda { },
    # "notebook.cellEditorBackground" => lambda { },
    # "notebook.focusedCellBackground" => lambda { },
    # "notebook.focusedCellBorder" => lambda { },
    # "notebook.focusedEditorBorder" => lambda { },
    # "notebook.inactiveFocusedCellBorder" => lambda { },
    # "notebook.inactiveSelectedCellBorder" => lambda { },
    # "notebook.outputContainerBackgroundColor" => lambda { },
    # "notebook.outputContainerBorderColor" => lambda { },
    # "notebook.selectedCellBackground" => lambda { },
    # "notebook.selectedCellBorder" => lambda { },
    # "notebook.symbolHighlightBackground" => lambda { },
    # "notebookScrollbarSlider.activeBackground" => lambda { },
    # "notebookScrollbarSlider.background" => lambda { },
    # "notebookScrollbarSlider.hoverBackground" => lambda { },
    # "notebookStatusErrorIcon.foreground" => lambda { },
    # "notebookStatusRunningIcon.foreground" => lambda { },
    # "notebookStatusSuccessIcon.foreground" => lambda { },
    # "notebookEditorOverviewRuler.runningCellForeground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#chart-colors
    # "charts.foreground" => lambda { },
    # "charts.lines" => lambda { },
    # "charts.red" => lambda { },
    # "charts.blue" => lambda { },
    # "charts.yellow" => lambda { },
    # "charts.orange" => lambda { },
    # "charts.green" => lambda { },
    # "charts.purple" => lambda { }

    # https://code.visualstudio.com/api/references/theme-color#ports-colors
    # "ports.iconRunningProcessForeground" => lambda { }

    # https://code.visualstudio.com/api/references/theme-color#comments-view-colors
    # "commentsView.resolvedIcon" => lambda { },
    # "commentsView.unresolvedIcon" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#action-bar-colors
    # "actionBar.toggledBackground" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#simple-find-widget
    # "simpleFindWidget.sashBorder" => lambda { },

    # https://code.visualstudio.com/api/references/theme-color#scm
    # "scm.historyItemAdditionsForeground" => lambda { },
    # "scm.historyItemDeletionsForeground" => lambda { },
    # "scm.historyItemStatisticsBorder" => lambda { },
    # "scm.historyItemSelectedStatisticsBorder" => lambda { }
  }

  options.transform_values(&:call)
end

def generate(txt_file)
  themes, tokens = read_define_txt(txt_file)

  themes.each do |theme|
    folder = "dist/#{theme}"
    FileUtils.mkdir_p(folder) unless File.directory?(folder)

    %w(light dark).each do |scheme|
      $scheme = scheme

      json = {
        "name" => tokens[scheme == "dark" ? "#{theme}.d" : theme],
        "colors" => map_colors(theme, tokens),
        "semanticHighlighting" => true,
        "tokenColors" => [],
      }

      file_name = scheme == "dark" ? "#{theme}-d" : theme

      File.open("#{folder}/#{file_name}.json", "w") do |file|
        file.write(JSON.pretty_generate(json))
      end
    end
  end
end

generate("define.txt")
