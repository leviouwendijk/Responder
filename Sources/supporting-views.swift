// import SwiftUI

// struct SelectableRow: View {
//     let title: String
//     let isSelected: Bool
//     let action: () -> Void
//     let animationDuration: TimeInterval

//     init(
//       title: String,
//       isSelected: Bool,
//       animationDuration: Double = 0.2,
//       action: @escaping () -> Void
//     ) {
//       self.title = title
//       self.isSelected = isSelected
//       self.animationDuration = animationDuration
//       self.action = action
//     }

//     var body: some View {
//         HStack {
//             if isSelected {
//                 Text(title)
//                     // .font(.headline)
//                     // .foregroundColor(Color("NearBlack"))
//                     .foregroundColor(Color.black)
//                     // .bold()
//             } else {
//                 Text(title)
//                     // .font(.headline)
//                     // .foregroundColor(Color("NearBlack"))
//                     // .foregroundColor(isSelected ? Color.black : Color.secondary)
//                     .foregroundColor(Color.secondary)
//             }
//             Spacer()
//         }
//         .padding(12)
//         .background(
//             isSelected
//                 ? Color.blue.opacity(0.3)
//                 : Color.clear
//         )
//         .cornerRadius(5)
//         .overlay(
//             RoundedRectangle(cornerRadius: 5)
//                 .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
//         )
//         .shadow(
//             color: isSelected ? Color.blue.opacity(0.1) : Color.white,
//             radius: 5
//         )
//         .contentShape(RoundedRectangle(
//           cornerRadius: 5
//         ))
//         .onTapGesture {
//             withAnimation(.easeInOut(duration: animationDuration)) {
//                 action()
//             }
//             // action()
//         }
//     }
// }

// struct SectionTitle: View {
//     let title: String
//     let width: CGFloat

//     init(
//       title: String,
//       width: CGFloat = 350,
//     ) {
//       self.title = title
//       self.width = width
//     }

//     var body: some View {
//         VStack(alignment: .center) {
//             Text(title)
//                 // .font(.system(.title3, design: .rounded))
//                 .fontWeight(.semibold)
//                 .foregroundColor(.secondary)
//                 .padding(.horizontal, 8)
//                 .frame(maxWidth: width)

//             line
//         }
//         .padding(.vertical, 8)
//     }

//     private var line: some View {
//         Rectangle()
//             .frame(height: 1)
//             .foregroundColor(Color.secondary.opacity(0.5))
//             .frame(maxWidth: width)
//     }
// }
