package com.maheshraikg.pdftoolkit.util

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * DataStore for persisting the user's pinned/favorite tool IDs shown at the
 * top of the Tools screen. Uses the same DataStore instance as
 * LanguageDataStore/ThemeManager for consistency.
 */
object FavoritesDataStore {

    private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "app_preferences")

    private val FAVORITE_TOOL_IDS_KEY = stringSetPreferencesKey("favorite_tool_ids")

    /**
     * Get the set of favorite tool IDs as a Flow. Emits an empty set if none saved yet.
     */
    fun getFavoriteToolIds(context: Context): Flow<Set<String>> {
        return context.dataStore.data.map { preferences ->
            preferences[FAVORITE_TOOL_IDS_KEY] ?: emptySet()
        }
    }

    /**
     * Toggle a tool's favorite status: adds it if absent, removes it if present.
     */
    suspend fun toggleFavorite(context: Context, toolId: String) {
        context.dataStore.edit { preferences ->
            val current = preferences[FAVORITE_TOOL_IDS_KEY] ?: emptySet()
            preferences[FAVORITE_TOOL_IDS_KEY] = if (toolId in current) current - toolId else current + toolId
        }
    }
}
