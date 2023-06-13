import time


class SyncService:
    @staticmethod
    def server_timestamp_ms() -> int:
        return int(time.time() * 1000)
