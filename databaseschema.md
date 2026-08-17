## Table `profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  Unique |
| `username` | `varchar` |  Nullable Unique |
| `display_name` | `varchar` |  |
| `bio` | `varchar` |  Nullable |
| `avatar_path` | `varchar` |  Nullable |
| `cover_path` | `varchar` |  Nullable |
| `is_private` | `bool` |  |
| `account_status` | `account_status` |  |
| `follower_count` | `int4` |  |
| `following_count` | `int4` |  |
| `post_count` | `int4` |  |
| `total_likes_received` | `int8` |  |
| `username_updated_at` | `timestamptz` |  Nullable |
| `last_active_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |
| `search_vector` | `tsvector` |  Nullable |
| `email` | `varchar` |  Nullable |
| `status` | `login_status` |  |
| `refer_code` | `varchar` |  Nullable Unique |
| `login_code` | `varchar` |  Nullable |



## Table `user_follows`

create table public.user_follow2_chunked (
  profile_id uuid not null,
  chunk integer not null,
  follower_profile_ids uuid[] null,
  
  following_profile_ids uuid[] null,
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint user_follow2_chunked_pkey primary key (id),
  constraint uq_profile_chunk unique (profile_id, chunk)
) TABLESPACE pg_default;

create index IF not exists idx_user_follow2_chunked_profile_id on public.user_follow2_chunked using btree (profile_id) TABLESPACE pg_default;

create index IF not exists idx_user_follow2_chunked_followers_gin on public.user_follow2_chunked using gin (follower_profile_ids) TABLESPACE pg_default;

create index IF not exists idx_user_follow2_chunked_following_gin on public.user_follow2_chunked using gin (following_profile_ids) TABLESPACE pg_default;

create trigger trg_user_follow2_chunked_updated_at BEFORE
update on user_follow2_chunked for EACH row
execute FUNCTION set_updated_at ();

## Table `posts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_id` | `uuid` |  |
| `caption` | `varchar` |  Nullable |
| `latitude` | `numeric` |  Nullable |
| `longitude` | `numeric` |  Nullable |
| `location_name` | `varchar` |  Nullable |
| `visibility` | `post_visibility` |  |
| `status` | `post_status` |  |
| `like_count` | `int4` |  |
| `comment_count` | `int4` |  |
| `save_count` | `int4` |  |
| `share_count` | `int4` |  |
| `view_count` | `int8` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |

## Table `post_media`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `post_id` | `uuid` |  |
| `media_order` | `int2` |  |
| `media_type` | `media_type` |  |
| `storage_path` | `varchar` |  |
| `thumbnail_path` | `varchar` |  Nullable |
| `width` | `int4` |  Nullable |
| `height` | `int4` |  Nullable |
| `duration_seconds` | `int2` |  Nullable |
| `file_size` | `int8` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `hashtags`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `post_count` | `int4` |  |
| `created_at` | `timestamptz` |  |

## Table `post_hashtags`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `post_id` | `uuid` | Primary |
| `hashtag_id` | `uuid` | Primary |
| `created_at` | `timestamptz` |  |

## Table `post_likes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `post_id` | `uuid` |  |
| `profile_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |

## Table `comments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `post_id` | `uuid` |  |
| `profile_id` | `uuid` |  |
| `parent_comment_id` | `uuid` |  Nullable |
| `content` | `varchar` |  |
| `like_count` | `int4` |  |
| `reply_count` | `int4` |  |
| `is_edited` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |

## Table `comment_likes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `comment_id` | `uuid` |  |
| `profile_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |

## Table `notifications`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `recipient_profile_id` | `uuid` |  |
| `actor_profile_id` | `uuid` |  |
| `notification_type` | `notification_type` |  |
| `post_id` | `uuid` |  Nullable |
| `comment_id` | `uuid` |  Nullable |
| `is_read` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `saved_posts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_id` | `uuid` |  |
| `post_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |

## Table `post_views`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `post_id` | `uuid` |  |
| `profile_id` | `uuid` |  Nullable |
| `watched_seconds` | `int2` |  |
| `completed` | `bool` |  |
| `created_at` | `timestamptz` |  |

## Table `communities`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `owner_profile_id` | `uuid` |  |
| `name` | `varchar` |  Unique |
| `description` | `varchar` |  Nullable |
| `avatar_path` | `varchar` |  Nullable |
| `banner_path` | `varchar` |  Nullable |
| `privacy` | `community_privacy` |  |
| `member_count` | `int4` |  |
| `post_count` | `int4` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `deleted_at` | `timestamptz` |  Nullable |

## Table `community_members`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `community_id` | `uuid` |  |
| `profile_id` | `uuid` |  |
| `role` | `community_member_role` |  |
| `status` | `community_member_status` |  |
| `joined_at` | `timestamptz` |  |
| `invited_by_profile_id` | `uuid` |  Nullable |

## Table `community_rules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `community_id` | `uuid` |  |
| `rule_order` | `int2` |  |
| `title` | `varchar` |  |
| `description` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `media_metadata`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `media_id` | `uuid` |  |
| `original_filename` | `varchar` |  Nullable |
| `original_file_size` | `int8` |  Nullable |
| `compressed_file_size` | `int8` |  Nullable |
| `mime_type` | `varchar` |  Nullable |
| `extension` | `varchar` |  Nullable |
| `width` | `int4` |  Nullable |
| `height` | `int4` |  Nullable |
| `duration_seconds` | `numeric` |  Nullable |
| `bitrate` | `int4` |  Nullable |
| `frame_rate` | `numeric` |  Nullable |
| `taken_at` | `timestamptz` |  Nullable |
| `latitude` | `numeric` |  Nullable |
| `longitude` | `numeric` |  Nullable |
| `device_make` | `varchar` |  Nullable |
| `device_model` | `varchar` |  Nullable |
| `os_name` | `varchar` |  Nullable |
| `app_version` | `varchar` |  Nullable |
| `compression_ratio` | `numeric` |  Nullable |
| `checksum_sha256` | `varchar` |  Nullable |
| `uploaded_at` | `timestamptz` |  |
| `upload_latitude` | `numeric` |  Nullable |
| `upload_longitude` | `numeric` |  Nullable |

## Table `community_bans`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `community_id` | `uuid` |  |
| `banned_profile_id` | `uuid` |  |
| `banned_by_profile_id` | `uuid` |  |
| `reason` | `varchar` |  Nullable |
| `expires_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `community_invites`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `community_id` | `uuid` |  |
| `sender_profile_id` | `uuid` |  |
| `receiver_profile_id` | `uuid` |  |
| `status` | `community_invite_status` |  |
| `expires_at` | `timestamptz` |  |
| `created_at` | `timestamptz` |  |
| `responded_at` | `timestamptz` |  Nullable |

## Table `report_reasons`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `description` | `varchar` |  Nullable |
| `applies_to` | `_report_target_type` |  |
| `is_active` | `bool` |  |
| `display_order` | `int2` |  |
| `created_at` | `timestamptz` |  |

## Table `reports`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `reporter_profile_id` | `uuid` |  |
| `reason_id` | `uuid` |  |
| `target_type` | `report_target_type` |  |
| `post_id` | `uuid` |  Nullable |
| `comment_id` | `uuid` |  Nullable |
| `profile_id` | `uuid` |  Nullable |
| `community_id` | `uuid` |  Nullable |
| `description` | `varchar` |  Nullable |
| `status` | `report_status` |  |
| `reviewed_by_profile_id` | `uuid` |  Nullable |
| `reviewed_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `report_actions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `report_id` | `uuid` |  |
| `moderator_profile_id` | `uuid` |  |
| `action` | `moderation_action` |  |
| `notes` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `moderation_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `moderator_profile_id` | `uuid` |  |
| `action` | `moderation_action` |  |
| `target_type` | `report_target_type` |  |
| `target_id` | `uuid` |  |
| `report_id` | `uuid` |  Nullable |
| `notes` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `app_versions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `platform` | `varchar` |  |
| `version_name` | `varchar` |  |
| `build_number` | `int4` |  |
| `minimum_supported_build` | `int4` |  |
| `force_update` | `bool` |  |
| `update_title` | `varchar` |  |
| `update_message` | `text` |  |
| `download_url` | `text` |  |
| `release_notes` | `text` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `user_follow2`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_id` | `uuid` |  Unique |
| `follower_profile_ids` | `_uuid` |  |
| `following_profile_ids` | `_uuid` |  |

## Table `post_shares`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `post_id` | `uuid` |  |
| `shared_by_profile_id` | `uuid` |  |
| `shared_with_profile_id` | `uuid` |  Nullable |
| `share_type` | `share_type` |  |
| `share_channel` | `varchar` |  Nullable |
| `message` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `user_follow2_chunked`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `profile_id` | `uuid` |  Nullable |
| `chunk` | `int4` |  Nullable |
| `follower_profile_ids` | `_uuid` |  Nullable |
| `following_profile_ids` | `_uuid` |  Nullable |
| `id` | `uuid` | Primary |

## Custom Types / Enums

### `privacy_level`

`public` | `private`

### `app_theme`

`system` | `light` | `dark`

### `app_language`

`en` | `hi`

### `account_status`

`ACTIVE` | `SUSPENDED` | `DEACTIVATED` | `DELETED`

### `follow_status`

`PENDING` | `ACCEPTED` | `REJECTED`

### `post_visibility`

`PUBLIC` | `FOLLOWERS` | `PRIVATE`

### `media_type`

`IMAGE` | `VIDEO`

### `post_status`

`ACTIVE` | `ARCHIVED` | `DELETED`

### `notification_type`

`POST_LIKE` | `POST_COMMENT` | `COMMENT_REPLY` | `COMMENT_LIKE` | `FOLLOW` | `COMMUNITY_INVITE`

### `community_privacy`

`PUBLIC` | `PRIVATE`

### `community_member_role`

`OWNER` | `ADMIN` | `MODERATOR` | `MEMBER`

### `community_member_status`

`PENDING` | `ACTIVE` | `LEFT` | `BANNED`

### `community_invite_status`

`PENDING` | `ACCEPTED` | `DECLINED` | `EXPIRED`

### `report_target_type`

`POST` | `COMMENT` | `PROFILE` | `COMMUNITY`

### `report_status`

`PENDING` | `UNDER_REVIEW` | `RESOLVED` | `REJECTED`

### `moderation_action`

`NONE` | `WARNING` | `CONTENT_REMOVED` | `ACCOUNT_SUSPENDED` | `ACCOUNT_BANNED` | `COMMUNITY_REMOVED`

### `share_type`

`INTERNAL` | `EXTERNAL`

### `login_status`

`pending` | `active` | `deactivated` | `blocked`

## RLS Policies

### `user_follows`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can view follows` | SELECT | public | PERMISSIVE | `true` | — |
| `Users can follow from their own account` | INSERT | public | PERMISSIVE | — | `(follower_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `Users can unfollow from their own account` | DELETE | public | PERMISSIVE | `(follower_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `post_likes`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can view post likes` | SELECT | public | PERMISSIVE | `true` | — |
| `Users can like posts` | INSERT | public | PERMISSIVE | — | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `Users can unlike their own likes` | DELETE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `comments`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can read comments` | SELECT | public | PERMISSIVE | `(deleted_at IS NULL)` | — |
| `Users can comment` | INSERT | public | PERMISSIVE | — | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `Users update own comments` | UPDATE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users delete own comments` | DELETE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `comment_likes`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can read comment likes` | SELECT | public | PERMISSIVE | `true` | — |
| `Users can like comments` | INSERT | public | PERMISSIVE | — | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `Users can unlike comments` | DELETE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `notifications`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can read own notifications` | SELECT | public | PERMISSIVE | `(recipient_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users can update own notifications` | UPDATE | public | PERMISSIVE | `(recipient_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users can create notifications as actor` | INSERT | public | PERMISSIVE | — | `(actor_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |

### `saved_posts`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can read own saved posts` | SELECT | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users can save posts` | INSERT | public | PERMISSIVE | — | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `Users can unsave posts` | DELETE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `post_views`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can create views` | INSERT | public | PERMISSIVE | — | `((profile_id IS NULL) OR (profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid()))))` |
| `Users can read own views` | SELECT | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `communities`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Public communities are readable` | SELECT | public | PERMISSIVE | `(deleted_at IS NULL)` | — |
| `Owner can update community` | UPDATE | public | PERMISSIVE | `(owner_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `community_rules`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can read community rules` | SELECT | public | PERMISSIVE | `true` | — |
| `Community owner can add rules` | INSERT | public | PERMISSIVE | — | `(community_id IN ( SELECT c.id    FROM (communities c      JOIN profiles p ON ((c.owner_profile_id = p.id)))   WHERE (p.user_id = auth.uid())))` |
| `Community owner can update rules` | UPDATE | public | PERMISSIVE | `(community_id IN ( SELECT c.id    FROM (communities c      JOIN profiles p ON ((c.owner_profile_id = p.id)))   WHERE (p.user_id = auth.uid())))` | — |
| `Community owner can delete rules` | DELETE | public | PERMISSIVE | `(community_id IN ( SELECT c.id    FROM (communities c      JOIN profiles p ON ((c.owner_profile_id = p.id)))   WHERE (p.user_id = auth.uid())))` | — |

### `community_bans`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Community moderators can read bans` | SELECT | public | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (community_members cm      JOIN profiles p ON ((p.id = cm.profile_id)))   WHERE ((cm.community_id = community_bans.community_id) AND (p.user_id = auth.uid()) AND (cm.role = ANY (ARRAY['OWNER'::community_member_role, 'ADMIN'::community_member_role, 'MODERATOR'::community_member_role])))))` | — |

### `community_invites`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users read own invites` | SELECT | public | PERMISSIVE | `(receiver_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users respond to own invites` | UPDATE | public | PERMISSIVE | `(receiver_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |

### `reports`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Users can read own reports` | SELECT | public | PERMISSIVE | `(reporter_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `Users can create reports` | INSERT | public | PERMISSIVE | — | `(reporter_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |

### `profiles`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `profiles_public_read` | SELECT | public | PERMISSIVE | `((deleted_at IS NULL) AND (account_status = 'ACTIVE'::account_status))` | — |
| `profiles_read_own` | SELECT | public | PERMISSIVE | `(user_id = auth.uid())` | — |
| `profiles_insert_own` | INSERT | public | PERMISSIVE | — | `(user_id = auth.uid())` |
| `profiles_update_own` | UPDATE | public | PERMISSIVE | `(user_id = auth.uid())` | `(user_id = auth.uid())` |
| `Allow auth admin to delete profiles` | DELETE | supabase_auth_admin | PERMISSIVE | `true` | — |

### `posts`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `posts_public_read` | SELECT | public | PERMISSIVE | `((deleted_at IS NULL) AND (status = 'ACTIVE'::post_status) AND (visibility = 'PUBLIC'::post_visibility))` | — |
| `posts_read_own` | SELECT | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | — |
| `posts_insert_own` | INSERT | public | PERMISSIVE | — | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |
| `posts_update_own` | UPDATE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |

### `post_media`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `post_media_public_read` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM posts p   WHERE ((p.id = post_media.post_id) AND (p.deleted_at IS NULL) AND (p.status = 'ACTIVE'::post_status) AND (p.visibility = 'PUBLIC'::post_visibility))))` | — |
| `post_media_read_owner` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_media.post_id) AND (pr.user_id = auth.uid()))))` | — |
| `post_media_insert_owner` | INSERT | authenticated | PERMISSIVE | — | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_media.post_id) AND (pr.user_id = auth.uid()))))` |
| `post_media_update_owner` | UPDATE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_media.post_id) AND (pr.user_id = auth.uid()))))` | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_media.post_id) AND (pr.user_id = auth.uid()))))` |
| `post_media_delete_owner` | DELETE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_media.post_id) AND (pr.user_id = auth.uid()))))` | — |

### `media_metadata`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `media_metadata_read_owner` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM ((post_media pm      JOIN posts p ON ((p.id = pm.post_id)))      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((pm.id = media_metadata.media_id) AND (pr.user_id = auth.uid()))))` | — |
| `media_metadata_insert_owner` | INSERT | authenticated | PERMISSIVE | — | `(EXISTS ( SELECT 1    FROM ((post_media pm      JOIN posts p ON ((p.id = pm.post_id)))      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((pm.id = media_metadata.media_id) AND (pr.user_id = auth.uid()))))` |
| `media_metadata_update_owner` | UPDATE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM ((post_media pm      JOIN posts p ON ((p.id = pm.post_id)))      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((pm.id = media_metadata.media_id) AND (pr.user_id = auth.uid()))))` | `(EXISTS ( SELECT 1    FROM ((post_media pm      JOIN posts p ON ((p.id = pm.post_id)))      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((pm.id = media_metadata.media_id) AND (pr.user_id = auth.uid()))))` |
| `media_metadata_delete_owner` | DELETE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM ((post_media pm      JOIN posts p ON ((p.id = pm.post_id)))      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((pm.id = media_metadata.media_id) AND (pr.user_id = auth.uid()))))` | — |

### `app_versions`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `app_versions_read` | SELECT | authenticated | PERMISSIVE | `(is_active = true)` | — |
| `app_versions_public_read` | SELECT | public | PERMISSIVE | `(is_active = true)` | — |

### `hashtags`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `hashtags_select_all` | SELECT | anon, authenticated | PERMISSIVE | `true` | — |

### `post_hashtags`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `post_hashtags_select_all` | SELECT | anon, authenticated | PERMISSIVE | `true` | — |
| `post_hashtags_insert_own_post` | INSERT | authenticated | PERMISSIVE | — | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_hashtags.post_id) AND (pr.user_id = auth.uid()))))` |
| `post_hashtags_delete_own_post` | DELETE | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (posts p      JOIN profiles pr ON ((pr.id = p.profile_id)))   WHERE ((p.id = post_hashtags.post_id) AND (pr.user_id = auth.uid()))))` | — |

### `community_members`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `community_members_select_if_member` | SELECT | authenticated | PERMISSIVE | `(EXISTS ( SELECT 1    FROM (community_members cm      JOIN profiles pr ON ((pr.id = cm.profile_id)))   WHERE ((cm.community_id = community_members.community_id) AND (pr.user_id = auth.uid()) AND (cm.status = 'ACTIVE'::community_member_status))))` | — |
| `community_members_insert_self` | INSERT | authenticated | PERMISSIVE | — | `(EXISTS ( SELECT 1    FROM profiles pr   WHERE ((pr.id = community_members.profile_id) AND (pr.user_id = auth.uid()))))` |
| `community_members_update_self_or_admin` | UPDATE | authenticated | PERMISSIVE | `((EXISTS ( SELECT 1    FROM profiles pr   WHERE ((pr.id = community_members.profile_id) AND (pr.user_id = auth.uid())))) OR (EXISTS ( SELECT 1    FROM (community_members cm      JOIN profiles pr ON ((pr.id = cm.profile_id)))   WHERE ((cm.community_id = community_members.community_id) AND (pr.user_id = auth.uid()) AND (cm.role = ANY (ARRAY['OWNER'::community_member_role, 'ADMIN'::community_member_role, 'MODERATOR'::community_member_role]))))))` | — |
| `community_members_delete_self_or_admin` | DELETE | authenticated | PERMISSIVE | `((EXISTS ( SELECT 1    FROM profiles pr   WHERE ((pr.id = community_members.profile_id) AND (pr.user_id = auth.uid())))) OR (EXISTS ( SELECT 1    FROM (community_members cm      JOIN profiles pr ON ((pr.id = cm.profile_id)))   WHERE ((cm.community_id = community_members.community_id) AND (pr.user_id = auth.uid()) AND (cm.role = ANY (ARRAY['OWNER'::community_member_role, 'ADMIN'::community_member_role, 'MODERATOR'::community_member_role]))))))` | — |

### `user_follow2`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can view follow2 data` | SELECT | public | PERMISSIVE | `true` | — |
| `Users can update their own following list` | UPDATE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |

### `post_shares`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `select_own_shares` | SELECT | public | PERMISSIVE | `((shared_by_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid()))) OR (shared_with_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid()))))` | — |
| `insert_own_shares` | INSERT | public | PERMISSIVE | — | `(shared_by_profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |

### `user_follow2_chunked`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `Anyone can view follow2 data` | SELECT | public | PERMISSIVE | `true` | — |
| `Users can update their own following list` | UPDATE | public | PERMISSIVE | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` | `(profile_id IN ( SELECT profiles.id    FROM profiles   WHERE (profiles.user_id = auth.uid())))` |