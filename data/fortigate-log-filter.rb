module FortigateLogFilter

  # to filter fortigate logs:
  # if any of the following items matches, the log will be dropped
  # deprecated
  FILTEROUT = {
      :logdesc => [
         'Admin logout successful',
         'Disk log rolled',
         'Disk log directory deleted',
         'Disk log file deleted',
         'FortiGate updated',
         'FortiGuard authentication status',
         'IPsec phase \d+ error',
         'Log rotation requested by forticron',
         'Outdated report database records deleted',
         'Progress IPsec phase \d+',
         'Report generated successfully',
         'Super admin entered VDOM',
         'SSL VPN statistics',
         'SSL VPN new connection',
         'SSL VPN tunnel up',
         'SSL VPN tunnel down',
         'SSL VPN alert',
         'SSL VPN exit error'
      ],
      :action => [],
      :user => [
         'networkguest'
      ]
  }

  # to filter fortigate logs:
  # any log of the following matches will be considered config changes.
  FILTERIN = {
      :logdesc => [
          'Interface status changed',
          'Object attribute configured',
          'Attribute configured',
          'Object configured',
          'Configuration changed'
      ]
  }
end