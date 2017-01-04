# bit-rot-detector
Detects if files within a file path have changed.

## Requirements
 * Bash
 * Redis

## Usage
### Build your index and hashes.
```
./build.sh {{ root_path }} {{ folder_name }} {{ options }}
```
where,
 * `root_path` - generally should be the root paths things mount too
 * `folder_name` - the drive name as it mounts to the system
 * `options` (enumeration)
  * `--verbose` (flag) - set this when running to get verbose feedback during execution (recommended for larger checks so you can see where you are at)
  * `--hashing-algorithm` (enumeration) - comma seperated list
    * `CRC` - cksum based, fast but not cryptographically secure but should be good enough for random errors
    * `md5` (default) - md5sum based, slower then CRC but less collisions
    * `sha1` - sha1sum based, faster then md5 but likely not as fast as CRC but is far more cryptographically secure

### Check your hashes
```
./check.sh {{ root_path }} {{ folder_name }} {{ options }}
```
