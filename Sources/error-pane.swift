
//             // new stdout pane:
//             Divider()

//             VStack(alignment: .leading) {
//                 // Toggle("Show Central Error Pane", isOn: $showErrorPane)
//                 StandardToggle(
//                     style: .switch,
//                     isOn: $showErrorPane,
//                     title: "Show Error Pane",
//                     subtitle: nil,
//                     width: 150
//                 )
//                 if showErrorPane {
//                     Text("Central Error Pane").bold()
//                     ScrollView {
//                         if (disabledFileSelected) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "exclamationmark.triangle.fill")
//                                     .font(.headline)
//                                     .accessibilityHidden(true)

//                                 Text("Select a template for this category")
//                                 .font(.subheadline)
//                                 .bold()
//                             }
//                             .foregroundColor(.black)
//                             .padding(.vertical, 10)
//                             .padding(.horizontal, 16)
//                             .background(Color.yellow)
//                             .cornerRadius(8)
//                             .padding(.horizontal)
//                             .transition(.move(edge: .top).combined(with: .opacity))
//                             .animation(.easeInOut, value: (disabledFileSelected))
//                         }

//                         if (anyInvalidConditionsCheck && emptySubjectWarning) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "exclamationmark.triangle.fill")
//                                     .font(.headline)
//                                     .accessibilityHidden(true)

//                                 Text("emptySubjectWarning: fill out a subject")
//                                 .font(.subheadline)
//                                 .bold()
//                             }
//                             .foregroundColor(.black)
//                             .padding(.vertical, 10)
//                             .padding(.horizontal, 16)
//                             .background(Color.yellow)
//                             .cornerRadius(8)
//                             .padding(.horizontal)
//                             .transition(.move(edge: .top).combined(with: .opacity))
//                             .animation(.easeInOut, value: (anyInvalidConditionsCheck && emptySubjectWarning))
//                         }

//                         if (anyInvalidConditionsCheck && emptyEmailWarning) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "exclamationmark.triangle.fill")
//                                     .font(.headline)
//                                     .accessibilityHidden(true)

//                                 Text("emptyEmailWarning: fill out an email or multiple")
//                                 .font(.subheadline)
//                                 .bold()
//                             }
//                             .foregroundColor(.black)
//                             .padding(.vertical, 10)
//                             .padding(.horizontal, 16)
//                             .background(Color.yellow)
//                             .cornerRadius(8)
//                             .padding(.horizontal)
//                             .transition(.move(edge: .top).combined(with: .opacity))
//                             .animation(.easeInOut, value: (anyInvalidConditionsCheck && emptyEmailWarning))
//                         }

//                         if (anyInvalidConditionsCheck && contactExtractionError) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "exclamationmark.triangle.fill")
//                                     .font(.headline)
//                                     .accessibilityHidden(true)

//                                 Text("ContactExtractionError: client or dog name is invalid")
//                                 .font(.subheadline)
//                                 .bold()
//                             }
//                             .foregroundColor(.white)
//                             .padding(.vertical, 10)
//                             .padding(.horizontal, 16)
//                             .background(Color.red)
//                             .cornerRadius(8)
//                             .padding(.horizontal)
//                             .transition(.move(edge: .top).combined(with: .opacity))
//                             .animation(.easeInOut, value: (anyInvalidConditionsCheck && contactExtractionError))
//                         }

//                         if (anyInvalidConditionsCheck && finalHtmlContainsRawVariables) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "exclamationmark.triangle.fill")
//                                     .font(.headline)
//                                     .accessibilityHidden(true)

//                                 Text("Please replace all raw template variables before sending.")
//                                     .font(.subheadline)
//                                     .bold()
//                             }
//                             .foregroundColor(.white)
//                             .padding(.vertical, 10)
//                             .padding(.horizontal, 16)
//                             .background(Color.red)
//                             .cornerRadius(8)
//                             .padding(.horizontal)
//                             .transition(.move(edge: .top).combined(with: .opacity))
//                             .animation(.easeInOut, value: (anyInvalidConditionsCheck && finalHtmlContainsRawVariables))
//                         }
//                     }
//                     .background(Color.black.opacity(0.05))
//                     .cornerRadius(6)
//                     .frame(maxHeight: 300)
//                 }

//             }
//             .frame(minWidth: 50)
//             // end of new stdout pane

//             // .frame(width: 400)
