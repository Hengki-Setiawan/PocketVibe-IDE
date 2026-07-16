enum SetupStep {
  notStarted,
  checkingTermux,
  promptInstallTermux,
  checkingTermuxApi,
  promptInstallTermuxApi,
  requestPermission,
  promptBootstrap,
  waitingBootstrapSignal,
  installingOpenCode,
  startingServer,
  healthCheck,
  done,
  failed,
}

extension SetupStepLabel on SetupStep {
  String get label {
    switch (this) {
      case SetupStep.notStarted: return 'Memulai...';
      case SetupStep.checkingTermux: return 'Memeriksa Termux';
      case SetupStep.promptInstallTermux: return 'Instal Termux';
      case SetupStep.checkingTermuxApi: return 'Memeriksa Termux:API';
      case SetupStep.promptInstallTermuxApi: return 'Instal Termux:API';
      case SetupStep.requestPermission: return 'Minta Izin';
      case SetupStep.promptBootstrap: return 'Bootstrap Awal';
      case SetupStep.waitingBootstrapSignal: return 'Menunggu Bootstrap';
      case SetupStep.installingOpenCode: return 'Memasang OpenCode';
      case SetupStep.startingServer: return 'Menyalakan Server';
      case SetupStep.healthCheck: return 'Memeriksa Koneksi';
      case SetupStep.done: return 'Selesai!';
      case SetupStep.failed: return 'Gagal';
    }
  }

  bool get isProgress => index >= SetupStep.installingOpenCode.index && index <= SetupStep.healthCheck.index;
  bool get isWaiting => this == SetupStep.waitingBootstrapSignal;
  bool get isPrompting => this == SetupStep.promptInstallTermux
      || this == SetupStep.promptInstallTermuxApi
      || this == SetupStep.promptBootstrap;
  bool get isTerminal => this == SetupStep.done || this == SetupStep.failed;
}
