# TEST-REPORT — Flow Prototype 01

_Generated: 2026-10-21T10:01:33Z. Full logs live under_ `artifacts/logs/`.

## Latest command records

- `artifacts/logs/build-simulator-20261020-205410.log`: 24727 bytes
  ```text
  error: error: cannot execute tool 'metal' due to missing Metal Toolchain; use: xcodebuild -downloadComponent MetalToolchain
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205533.log`: 64680 bytes
  ```text
  FlowApp/Shaders/FlowShaders.metal:174:17: error: no matching function for call to 'uvOf'
  FlowApp/Shaders/FlowShaders.metal:175:20: error: no member named 'sample' in 'metal::texture2d<float, metal::access::read, metal::memory_coherence_threadgroup>'
  FlowApp/Shaders/FlowShaders.metal:205:17: error: no matching function for call to 'uvOf'
  FlowApp/Shaders/FlowShaders.metal:206:31: error: no member named 'sample' in 'metal::texture2d<float, metal::access::read, metal::memory_coherence_threadgroup>'
  fatal error: too many errors emitted, stopping now [-ferror-limit=]
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205621.log`: 54386 bytes
  ```text
  FlowApp/Shaders/FlowShaders.metal:96:9: error: no matching member function for call to 'write'
  FlowApp/Shaders/FlowShaders.metal:126:9: error: no matching member function for call to 'write'
  FlowApp/Shaders/FlowShaders.metal:144:9: error: no matching member function for call to 'write'
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205640.log`: 75386 bytes
  ```text
      |               `- error: initializer for conditional binding must have Optional type, not 'UnsafeMutablePointer<UInt8>'
  FlowApp/Rendering/MetalRenderer.swift:532:21: error: extra arguments at positions #1, #3 in call
      |                     `- error: extra arguments at positions #1, #3 in call
  FlowApp/Rendering/MetalRenderer.swift:532:22: error: missing argument for parameter 'buffer' in call
      |                      `- error: missing argument for parameter 'buffer' in call
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205703.log`: 59386 bytes
  ```text
      |                     `- error: incorrect argument labels in call (have 'texture:range:level:', expected 'buffer:range:value:')
  FlowApp/Rendering/MetalRenderer.swift:535:31: error: argument type 'any MTLTexture' does not conform to expected type 'MTLBuffer'
      |                               `- error: argument type 'any MTLTexture' does not conform to expected type 'MTLBuffer'
  FlowApp/Rendering/MetalRenderer.swift:535:55: error: cannot convert value of type 'Int' to expected argument type 'UInt8'
      |                                                       `- error: cannot convert value of type 'Int' to expected argument type 'UInt8'
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205728.log`: 22866 bytes
  ```text
  FlowApp/Rendering/TexturePool.swift:58:59: error: return from initializer without initializing all stored properties
      |                                                           `- error: return from initializer without initializing all stored properties
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205738.log`: 57316 bytes
  ```text
  FlowApp/UI/DebugOverlay.swift:40:58: error: cannot convert value of type 'Double' to expected argument type 'Float'
      |                                                          `- error: cannot convert value of type 'Double' to expected argument type 'Float'
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261020-205745.log`: 62978 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-210755.log`: 6281 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-210919.log`: 59523 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211020.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211205.log`: 63127 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211211.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211253.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211318.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211342.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211407.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211431.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211542.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211607.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211632.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211656.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211721.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211745.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-211939.log`: 5193 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-212004.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261020-212029.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000708.log`: 4147 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000733.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000757.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000832.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000900.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000925.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-000950.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001016.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001041.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001117.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001142.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001208.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001233.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001259.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001325.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001400.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001426.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001452.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001553.log`: 3059 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001619.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001647.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001712.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001740.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001806.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001831.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001857.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-001922.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002008.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002034.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002059.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002141.log`: 3059 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002207.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002238.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002355.log`: 18318 bytes
  ```text
  FlowApp/App/FlowApp.swift:12:45: error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
     |                                             `- error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261021-002427.log`: 16587 bytes
  ```text
  FlowApp/App/FlowApp.swift:12:45: error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
     |                                             `- error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261021-002437.log`: 16587 bytes
  ```text
  FlowApp/App/FlowApp.swift:12:45: error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
     |                                             `- error: contextual closure type '(ScenePhase) -> Void' expects 1 argument, but 2 were used in closure body
  ** BUILD FAILED **
  ```
- `artifacts/logs/build-simulator-20261021-002453.log`: 58841 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002510.log`: 57575 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002533.log`: 66383 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002536.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002602.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002635.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002700.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002726.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002752.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002817.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002843.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002913.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002929.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-002945.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-003016.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-003042.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-003107.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004428.log`: 67892 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004433.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004459.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004544.log`: 66277 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004549.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004625.log`: 6735 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004627.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004701.log`: 62975 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004704.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004749.log`: 6735 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004750.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004828.log`: 62975 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004831.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004907.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-004933.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005004.log`: 62975 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005007.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005054.log`: 62975 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005057.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005133.log`: 64258 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005138.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005216.log`: 62975 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005219.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005251.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005316.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005342.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005407.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005433.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005458.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005535.log`: 6735 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005537.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005603.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005628.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005654.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005719.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005753.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-005818.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010009.log`: 5193 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010034.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010105.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010130.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010156.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010224.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010240.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010256.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-010312.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020604.log`: 63179 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020609.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020650.log`: 65806 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020653.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020719.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020744.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020857.log`: 63767 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020904.log`: 57593 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-020937.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021015.log`: 66295 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021018.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021053.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021118.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021144.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021209.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021235.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021301.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021331.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021353.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021415.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021438.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021542.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021608.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021633.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021743.log`: 5193 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-021809.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023347.log`: 6735 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023351.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023424.log`: 62993 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023428.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023501.log`: 65019 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023505.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023535.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023601.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023627.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023652.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023718.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023801.log`: 6735 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023804.log`: 4709 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023837.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023902.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023928.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-023954.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024019.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024058.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024120.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024142.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024205.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024540.log`: 6281 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-024948.log`: 63763 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-025041.log`: 57593 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-025514.log`: 5797 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-025851.log`: 6281 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-025919.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-025945.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-030011.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-030037.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/build-simulator-20261021-030104.log`: 2034 bytes
  ```text
  ** BUILD SUCCEEDED **
  ```
- `artifacts/logs/host-smoke-20261020-204151.log`: 2794 bytes
  ```text
  HostSmoke/main.swift:131:1: error: expressions are not allowed at the top level
      | `- error: expressions are not allowed at the top level
  HostSmoke/main.swift:132:1: error: expressions are not allowed at the top level
      | `- error: expressions are not allowed at the top level
  HostSmoke/main.swift:133:1: error: expressions are not allowed at the top level
      | `- error: expressions are not allowed at the top level
  ```
- `artifacts/logs/host-smoke-20261020-204154.log`: 4858 bytes
  ```text
  HostSmoke/main.swift:127:15: error: cannot find 'FlowRenderer' in scope
      |               `- error: cannot find 'FlowRenderer' in scope
  HostSmoke/main.swift:10:15: error: main actor-isolated var 'passed' can not be mutated from a nonisolated context
      |               `- error: main actor-isolated var 'passed' can not be mutated from a nonisolated context
  HostSmoke/main.swift:11:12: error: main actor-isolated var 'failed' can not be mutated from a nonisolated context
      |            `- error: main actor-isolated var 'failed' can not be mutated from a nonisolated context
  ```
- `artifacts/logs/host-smoke-20261020-204203.log`: 3465 bytes
  ```text
  ```
- `artifacts/logs/host-smoke-20261020-204248.log`: 3475 bytes
  ```text
  ```
- `artifacts/logs/host-smoke-20261021-021738.log`: 3475 bytes
  ```text
  ```
- `artifacts/logs/host-smoke-20261021-030129.log`: 3475 bytes
  ```text
  ```
- `artifacts/logs/perf-simulator-ipad.log`: 693 bytes
  ```text
  ```
- `artifacts/logs/perf-simulator-iphone.log`: 1176 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261020-211431.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261020-211745.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-001041.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-001324.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-001922.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-002843.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-005458.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-005719.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-021301.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-023717.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-024019.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-crossing-20261021-030103.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261020-211317.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261020-211631.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-000950.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-001208.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-001831.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-002726.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-005341.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-010009.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-021143.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-023601.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-023902.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-fast-swipe-20261021-025945.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261020-211253.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261020-211607.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-000708.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-000925.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-001142.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-001805.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-002602.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-002700.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-005316.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-005602.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-010034.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-020744.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-021118.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-023535.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-023836.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-slow-stroke-20261021-025919.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261020-211342.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261020-211656.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261020-211939.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261020-212004.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261020-212028.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-000733.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-000832.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001233.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001400.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001426.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001452.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001553.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001618.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001646.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-001712.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002008.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002033.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002059.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002141.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002207.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002536.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-002751.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-003016.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-003041.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-003107.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-004458.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-005407.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-005628.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-005752.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-005818.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-010105.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-010130.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-010156.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-020718.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021209.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021542.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021608.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021633.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021743.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-021808.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-023626.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-023928.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-spiral-20261021-030011.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261020-210754.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261020-210918.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261020-211020.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261020-211211.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261020-211542.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-000757.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-000859.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-001116.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-001740.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-002635.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004433.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004548.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004627.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004703.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004750.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004831.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004907.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-004932.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005007.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005056.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005138.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005219.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005250.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-005537.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-020609.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-020653.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-021018.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-021052.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-023351.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-023428.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-023504.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-023804.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-tap-20261021-025850.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261020-211406.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261020-211720.log`: 143 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-001015.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-001259.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-001857.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-002817.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-005433.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-005654.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-021235.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-023652.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-023953.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/replay-two-fingers-20261021-030037.log`: 144 bytes
  ```text
  ```
- `artifacts/logs/test-simulator-20261020-205752.log`: 133820 bytes
  ```text
  FlowTests/ReplayAndFluidTests.swift:10:34: error: cannot convert value of type 'ReplayAndFluidTests.Type' to expected argument type 'AnyClass' (aka 'any AnyObject.Type')
     |                                  `- error: cannot convert value of type 'ReplayAndFluidTests.Type' to expected argument type 'AnyClass' (aka 'any AnyObject.Type')
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261020-205801.log`: 131832 bytes
  ```text
  Test Suite 'All tests' started at 2026-10-20 20:58:14.281.
  Test Suite 'All tests' passed at 2026-10-20 20:58:14.281.
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261020-205939.log`: 109276 bytes
  ```text
  Test Suite 'All tests' started at 2026-10-20 20:59:47.834.
  Test Suite 'All tests' passed at 2026-10-20 20:59:47.834.
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261020-210007.log`: 35340 bytes
  ```text
  Test Suite 'All tests' started at 2026-10-20 21:00:12.274.
  Test Suite 'All tests' passed at 2026-10-20 21:00:12.274.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261020-210015.log`: 21200 bytes
  ```text
  FlowUITests/FlowUITests.swift:49: error: -[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures] : Failed to tap "Choose gesture replay fixture" Button: No matches found for Elements matching predicate '"Choose gesture replay fixture" IN identifiers' from input {(
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' failed (10.462 seconds).
  Test Suite 'FlowUITests' failed at 2026-10-20 21:00:56.643.
  Test Suite 'FlowUITests.xctest' failed at 2026-10-20 21:00:56.645.
  Test Suite 'All tests' failed at 2026-10-20 21:00:56.646.
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261020-210559.log`: 149758 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' failed (3.374 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.598 seconds).
  Test Suite 'FlowUITests' failed at 2026-10-20 21:06:32.453.
  Test Suite 'FlowUITests.xctest' failed at 2026-10-20 21:06:32.453.
  Test Suite 'All tests' failed at 2026-10-20 21:06:32.454.
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261020-210707.log`: 28387 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.313 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.632 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-20 21:07:37.824.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-20 21:07:37.825.
  Test Suite 'All tests' passed at 2026-10-20 21:07:37.826.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261020-211926.log`: 45035 bytes
  ```text
  Test Suite 'All tests' started at 2026-10-20 21:19:30.894.
  Test Suite 'All tests' passed at 2026-10-20 21:19:30.894.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261021-003139.log`: 62446 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.290 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.650 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-21 00:32:13.059.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 00:32:13.060.
  Test Suite 'All tests' passed at 2026-10-21 00:32:13.061.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261021-005844.log`: 59374 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.449 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.598 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-21 00:59:15.901.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 00:59:15.902.
  Test Suite 'All tests' passed at 2026-10-21 00:59:15.903.
  ** TEST FAILED **
  ```
- `artifacts/logs/test-simulator-20261021-005932.log`: 48736 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.298 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.583 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-21 01:00:04.326.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 01:00:04.327.
  Test Suite 'All tests' passed at 2026-10-21 01:00:04.328.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261021-021702.log`: 59256 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.376 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.849 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-21 02:17:35.614.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 02:17:35.615.
  Test Suite 'All tests' passed at 2026-10-21 02:17:35.616.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261021-024227.log`: 58385 bytes
  ```text
  Test Case '-[FlowUITests.FlowUITests testLaunchAndCanvasAccessibilityLabel]' passed (3.388 seconds).
  Test Case '-[FlowUITests.FlowUITests testReplayMenuListsStandardFixtures]' passed (6.740 seconds).
  Test Suite 'FlowUITests' passed at 2026-10-21 02:42:59.580.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 02:42:59.581.
  Test Suite 'All tests' passed at 2026-10-21 02:42:59.581.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/test-simulator-20261021-025519.log`: 203970 bytes
  ```text
  Test Case '-[FlowUITests.StabilityTests testHundredPauseClearResumeCycles]' passed (48.775 seconds).
  Test Case '-[FlowUITests.StabilityTests testSustainedRunStaysResponsive]' passed (95.323 seconds).
  Test Suite 'StabilityTests' passed at 2026-10-21 02:58:50.357.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 02:58:50.358.
  Test Suite 'All tests' passed at 2026-10-21 02:58:50.359.
  ** TEST SUCCEEDED **
  ```
- `artifacts/logs/verify-all-20261021-025511.log`: 6474 bytes
  ```text
  Test Case '-[FlowUITests.StabilityTests testHundredPauseClearResumeCycles]' passed (48.775 seconds).
  Test Case '-[FlowUITests.StabilityTests testSustainedRunStaysResponsive]' passed (95.323 seconds).
  Test Suite 'StabilityTests' passed at 2026-10-21 02:58:50.357.
  Test Suite 'FlowUITests.xctest' passed at 2026-10-21 02:58:50.358.
  Test Suite 'All tests' passed at 2026-10-21 02:58:50.359.
  ** TEST SUCCEEDED **
  ```

## Capture evidence

- `artifacts/captures/crossing/crossing_0.00.png`
- `artifacts/captures/crossing/crossing_0.50.png`
- `artifacts/captures/crossing/crossing_1.00.png`
- `artifacts/captures/crossing/crossing_1.52.png`
- `artifacts/captures/crossing/crossing_2.02.png`
- `artifacts/captures/crossing/crossing_3.52.png`
- `artifacts/captures/crossing/crossing_9.52.png`
- `artifacts/captures/fast-swipe/fast-swipe_0.00.png`
- `artifacts/captures/fast-swipe/fast-swipe_0.50.png`
- `artifacts/captures/fast-swipe/fast-swipe_0.83.png`
- `artifacts/captures/fast-swipe/fast-swipe_1.00.png`
- `artifacts/captures/fast-swipe/fast-swipe_1.33.png`
- `artifacts/captures/fast-swipe/fast-swipe_2.83.png`
- `artifacts/captures/fast-swipe/fast-swipe_8.83.png`
- `artifacts/captures/ipad-portrait.png`
- `artifacts/captures/ipad/spiral_3.20.png`
- `artifacts/captures/ipad/spiral_3.70.png`
- `artifacts/captures/ipad/spiral_5.20.png`
- `artifacts/captures/slow-stroke/slow-stroke_0.00.png`
- `artifacts/captures/slow-stroke/slow-stroke_0.50.png`
- `artifacts/captures/slow-stroke/slow-stroke_1.00.png`
- `artifacts/captures/slow-stroke/slow-stroke_12.22.png`
- `artifacts/captures/slow-stroke/slow-stroke_4.22.png`
- `artifacts/captures/slow-stroke/slow-stroke_4.72.png`
- `artifacts/captures/slow-stroke/slow-stroke_6.22.png`
- `artifacts/captures/spiral-mainonly/spiral_0.00.png`
- `artifacts/captures/spiral-mainonly/spiral_0.50.png`
- `artifacts/captures/spiral-mainonly/spiral_1.00.png`
- `artifacts/captures/spiral-mainonly/spiral_10.00.png`
- `artifacts/captures/spiral-mainonly/spiral_10.10.png`
- `artifacts/captures/spiral-mainonly/spiral_10.50.png`
- `artifacts/captures/spiral-mainonly/spiral_12.00.png`
- `artifacts/captures/spiral-mainonly/spiral_18.00.png`
- `artifacts/captures/spiral-nobloom/spiral_0.00.png`
- `artifacts/captures/spiral-nobloom/spiral_0.50.png`
- `artifacts/captures/spiral-nobloom/spiral_1.00.png`
- `artifacts/captures/spiral-nobloom/spiral_10.00.png`
- `artifacts/captures/spiral-nobloom/spiral_10.10.png`
- `artifacts/captures/spiral-nobloom/spiral_10.50.png`
- `artifacts/captures/spiral-nobloom/spiral_12.00.png`
- `artifacts/captures/spiral-nobloom/spiral_18.00.png`
- `artifacts/captures/spiral/spiral_0.00.png`
- `artifacts/captures/spiral/spiral_0.50.png`
- `artifacts/captures/spiral/spiral_1.00.png`
- `artifacts/captures/spiral/spiral_11.20.png`
- `artifacts/captures/spiral/spiral_3.20.png`
- `artifacts/captures/spiral/spiral_3.70.png`
- `artifacts/captures/spiral/spiral_5.20.png`
- `artifacts/captures/tap/tap_0.00.png`
- `artifacts/captures/tap/tap_0.24.png`
- `artifacts/captures/tap/tap_0.50.png`
- `artifacts/captures/tap/tap_0.74.png`
- `artifacts/captures/tap/tap_1.00.png`
- `artifacts/captures/tap/tap_2.24.png`
- `artifacts/captures/tap/tap_8.24.png`
- `artifacts/captures/two-fingers/two-fingers_0.00.png`
- `artifacts/captures/two-fingers/two-fingers_0.50.png`
- `artifacts/captures/two-fingers/two-fingers_1.00.png`
- `artifacts/captures/two-fingers/two-fingers_1.62.png`
- `artifacts/captures/two-fingers/two-fingers_2.12.png`
- `artifacts/captures/two-fingers/two-fingers_3.62.png`
- `artifacts/captures/two-fingers/two-fingers_9.62.png`
- `artifacts/captures/ui-collapsed.png`

## Status (current)

| Phase | Status | Evidence |
|---|---|---|
| P0 environment | see docs/ENVIRONMENT.md | probe log |
| P0 project gen | blocked without Xcode | — |
| P1..P7 | pending toolchain | — |

_This report is regenerated by `scripts/report.sh`._
