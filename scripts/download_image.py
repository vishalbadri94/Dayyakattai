import requests
import os

def main():
    url = "https://cf-images.assettype.com/TNIE/import/2016/6/24/22/original/Dayakattai.jpg"
    out_dir = r"C:\Users\visha\.gemini\antigravity-ide\brain\5e0e458c-0fbb-49bd-8b36-9a5f05f10c02"
    out_path = os.path.join(out_dir, "dayakattai_rough.jpg")
    
    print(f"Downloading image from {url}...")
    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        with open(out_path, "wb") as f:
            f.write(response.content)
        print(f"Image successfully downloaded and saved to {out_path}")
    except Exception as e:
        print(f"Error downloading image: {e}")

if __name__ == "__main__":
    main()
