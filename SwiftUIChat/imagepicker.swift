//
//  imagepicker.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 31/05/24.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    
    @Binding var image: UIImage?
    private let controller = UIImagePickerController()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update code if needed
    }
}
