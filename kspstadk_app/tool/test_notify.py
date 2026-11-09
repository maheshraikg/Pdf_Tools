"""Unit tests for tool/notify.py (run: python3 -m unittest discover -s tool)."""

import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import notify  # noqa: E402

FIX = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test", "fixtures")


class NotifyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = notify.load_config()
        cls.tmap = notify.topic_map(cls.cfg)
        with open(os.path.join(FIX, "posts_embed_20.json"), encoding="utf-8") as f:
            cls.posts = {p["id"]: p for p in json.load(f)}

    def test_lba_class_post_topics(self):
        # 57951: 4 TH STANDARD + 4 ನೇ ತರಗತಿ + LBA
        self.assertEqual(notify.topics_for(self.posts[57951], self.tmap), ["all", "lba", "class_4"])

    def test_information_post_topics(self):
        self.assertEqual(notify.topics_for(self.posts[58077], self.tmap), ["all", "info"])

    def test_single_condition_for_up_to_five_topics(self):
        self.assertEqual(notify.conditions(["all", "lba", "class_4"]),
                         ["'all' in topics || 'lba' in topics || 'class_4' in topics"])
        self.assertEqual(len(notify.conditions(["a", "b", "c", "d", "e", "f"])), 2)

    def test_message_shape(self):
        msg = notify.build_message(self.posts[57951], self.cfg, "'all' in topics")["message"]
        self.assertEqual(msg["data"]["post_id"], "57951")
        self.assertTrue(msg["data"]["url"].startswith("https://kspstadk.com/"))
        self.assertNotIn("&#", msg["notification"]["title"])
        self.assertEqual(msg["android"]["notification"]["channel_id"], "kspstadk_posts")
        self.assertIn("LBA", msg["notification"]["body"])


if __name__ == "__main__":
    unittest.main()
