import sys
from youtube_transcript_api import YouTubeTranscriptApi

def main():
    video_id = "_Majqdi2CE8"
    print(f"Fetching transcript for video ID: {video_id}...")
    try:
        # Get transcript directly
        data = YouTubeTranscriptApi().fetch(video_id, languages=['hi'])
        
        # Save transcript to file
        output_file = "video_transcript.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            for entry in data:
                text = entry.text
                start = entry.start
                f.write(f"[{start:.2f}s] {text}\n")
                
        print(f"Successfully saved transcript to {output_file}")
        
    except Exception as e:
        print(f"Error fetching transcript: {e}")

if __name__ == "__main__":
    main()
