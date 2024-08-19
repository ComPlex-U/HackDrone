import os
import time
import firebase_admin
from firebase_admin import credentials, storage
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from datetime import datetime

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'tese-25f7c.appspot.com'
})

bucket = storage.bucket()

def upload_to_firebase(file_path):
    try:
        timestamp = datetime.now().strftime('%Y-%m-%d_%H:%M')
        blob_path = f"{timestamp}/{os.path.basename(file_path)}"
        blob = bucket.blob(blob_path)
        blob.upload_from_filename(file_path)
        print(f'Arquivo {file_path} enviado para o Firebase Storage em {blob_path}.')
    except Exception as e:
        print(f'Erro ao enviar {file_path} para o Firebase Storage: {e}')

class Watcher(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory:
            print(f"Arquivo criado: {event.src_path}")
            upload_to_firebase(event.src_path)

def main():
    folder_to_watch = "session"
    if not os.path.isdir(folder_to_watch):
        print(f"Pasta {folder_to_watch} não encontrada.")
        return
    
    event_handler = Watcher()
    observer = Observer()
    observer.schedule(event_handler, folder_to_watch, recursive=False)
    observer.start()
    print(f"Monitorando a pasta: {folder_to_watch}")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        observer.join()

if __name__ == "__main__":
    main()