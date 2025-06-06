import Foundation
import SwiftUI
import Contacts
import EventKit
import plate
import Economics
import Compositions
import ViewComponents
import Interfaces
import Implementations

struct Responder: View {
    @EnvironmentObject var viewmodel: ResponderViewModel

    var body: some View {
        VStack {
            HStack {
                MailerAPIPathSelectionView(
                    viewModel: viewmodel.apiPathVm
                )
                .frame(width: 450)

                VariablesView(
                    viewmodel: viewmodel
                )
                .frame(minWidth: 380)

                Divider()

                ValuesPaneView(
                    viewmodel: viewmodel
                )
                .frame(minWidth: 400)
            }
            .padding()

            ExecuteMailerView(
                viewmodel: viewmodel
            )
            .padding(.top, 8)
        }
    }
}
