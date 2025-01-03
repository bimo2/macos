// https://hyper.is#cfg

module.exports = {
  config: {
    updateChannel: 'stable',
    fontSize: 12.5,
    fontFamily: 'SF Mono',
    fontWeight: 'normal',
    fontWeightBold: 'bold',
    lineHeight: 1.075,
    letterSpacing: 0,
    cursorColor: '#F2FF00',
    cursorAccentColor: '#000000',
    cursorShape: 'BLOCK',
    cursorBlink: true,
    foregroundColor: '#FFFFFF',
    backgroundColor: '#000000A6',
    selectionColor: '#F2FF0040',
    borderColor: '#00000000',
    css: '',
    termCSS: '',
    workingDirectory: '',
    showHamburgerMenu: '',
    showWindowControls: '',
    padding: '12px 16px',
    colors: {
      red: '#FF1235',
      green: '#2CF246',
      yellow: '#F2FF00',
      blue: '#00A6FF',
      magenta: '#FF4FAA',
      cyan: '#30E6E6',
      white: '#FFFFFF',
      lightBlack: '#000000',
      lightRed: '#FF1235',
      lightGreen: '#2CF246',
      lightYellow: '#F2FF00',
      lightBlue: '#00A6FF',
      lightMagenta: '#FF4FAA',
      lightCyan: '#30E6E6',
      lightWhite: '#FFFFFF',
    },
    shell: '/bin/zsh',
    shellArgs: ['--login'],
    env: {},
    bell: 'SOUND',
    copyOnSelect: false,
    defaultSSHApp: true,
    quickEdit: false,
    macOptionSelectionMode: 'vertical',
    webGLRenderer: true,
    webLinksActivationKey: '',
    disableLigatures: true,
    disableAutoUpdates: false,
    screenReaderMode: false,
    preserveCWD: true,
  },
  plugins: [],
  localPlugins: [],
  keymaps: {},
};
