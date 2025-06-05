import Foundation
import Combine

/// Holds all of your “stdout” and any other cross‐tab state
public class MailerViewModel: ObservableObject {
    @Published public var mailerOutput: String = ""
    @Published public var sharedMailerCommandCopy: String = ""
}
