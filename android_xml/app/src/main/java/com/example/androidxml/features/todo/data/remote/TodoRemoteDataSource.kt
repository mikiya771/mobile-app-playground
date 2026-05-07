package com.example.androidxml.features.todo.data.remote

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query

interface TodoApiService {
    @GET("todos")
    suspend fun fetchTodos(@Query("_limit") limit: Int = 20): List<TodoDto>
}

class TodoRemoteDataSource {
    private val service: TodoApiService by lazy {
        val logging = HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC }
        val client = OkHttpClient.Builder().addInterceptor(logging).build()
        Retrofit.Builder()
            .baseUrl("https://jsonplaceholder.typicode.com/")
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TodoApiService::class.java)
    }

    suspend fun fetchAll(): List<TodoDto> = service.fetchTodos()
}
