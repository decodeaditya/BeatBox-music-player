import 'package:hive/hive.dart'; // <--- ADD THIS IMPORT

// Make sure the part 'songDataModel.g.dart' is NOT used if you're doing this manually.

@HiveType(typeId: 0) // <--- ADD THIS ANNOTATION: Assign a unique type ID for SongData (e.g., 0)
class SongData {
  @HiveField(0) // <--- ADD THIS ANNOTATION: Assign a unique field ID for 'title'
  final String title;
  @HiveField(1) // <--- ADD THIS ANNOTATION: Assign a unique field ID for 'artists'
  final dynamic artists; // Assuming 'artists' can be dynamic/List<dynamic> from your declaration
  @HiveField(2) // <--- ADD THIS ANNOTATION: Assign a unique field ID for 'imgUrl'
  final String imgUrl;
  @HiveField(3) // <--- ADD THIS ANNOTATION: Assign a unique field ID for 'audioUrl'
  final String audioUrl;
  @HiveField(4) // <--- ADD THIS ANNOTATION: Assign a unique field ID for 'id'
  final String id;

  SongData({
    required this.title,
    required this.artists,
    required this.imgUrl,
    required this.audioUrl,
    required this.id
  });

  // Optional: For better debugging and comparison, if not already present
  @override
  String toString() {
    return 'SongData(id: $id, title: $title, artists: $artists)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SongData &&
        other.id == id &&
        other.title == title &&
        other.artists == artists &&
        other.imgUrl == imgUrl &&
        other.audioUrl == audioUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           title.hashCode ^
           artists.hashCode ^
           imgUrl.hashCode ^
           audioUrl.hashCode;
  }
}

// --- ADD THIS MANUAL TYPE ADAPTER CLASS BELOW YOUR SongData CLASS ---
// This class tells Hive how to serialize (write) and deserialize (read) your SongData object.

class SongDataAdapter extends TypeAdapter<SongData> {
  @override
  final int typeId = 0; // <--- This must match the typeId you used in @HiveType(typeId: 0)

  @override
  SongData read(BinaryReader reader) {
    // Read the number of fields that were written
    final numOfFields = reader.readByte();
    // Create a map to store the fields, keyed by their field ID
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Reconstruct the SongData object from the read fields
    return SongData(
      title: fields[0] as String,
      artists: fields[1], // Artists can be dynamic, so no 'as String' or 'as List<dynamic>' cast needed here if it was dynamic
      imgUrl: fields[2] as String,
      audioUrl: fields[3] as String,
      id: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SongData obj) {
    // Write the number of fields you are going to write
    writer.writeByte(5); // We have 5 fields in SongData

    // Write each field's ID followed by its value
    writer.writeByte(0);
    writer.write(obj.title);
    writer.writeByte(1);
    writer.write(obj.artists);
    writer.writeByte(2);
    writer.write(obj.imgUrl);
    writer.writeByte(3);
    writer.write(obj.audioUrl);
    writer.writeByte(4);
    writer.write(obj.id);
  }
}